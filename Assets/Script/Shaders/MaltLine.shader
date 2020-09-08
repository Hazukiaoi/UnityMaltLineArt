//some code from https://github.com/BlenderNPR/BEER/blob/master/BlenderMalt/MaltPath/Malt/Render/Shaders/Filters/Line.glsl

Shader "Unlit/MaltLine"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #define LINE_DEPTH_MODE_NEAR 0
            #define LINE_DEPTH_MODE_FAR  1
            #define LINE_DEPTH_MODE_ANY  2

            //#define clamp(t, min, max)
            #define map_range(value, from_min, from_max, to_min, to_max) (lerp(to_min, to_max, (value - from_min) / (from_max - from_min)))
            #define map_range_clamped(value, from_min, from_max, to_min, to_max) clamp(map_range(value, from_min, from_max, to_min, to_max), to_min, to_max)


            struct LineOutput
            {
                float delta_distance;
                float delta_angle;
                bool id_boundary;
            };

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _ObjectIDTex;
            uniform float4 _MainTex_TexelSize;
            uniform float4 lineColor;

			sampler2D _CameraDepthTexture;
			sampler2D _CameraDepthNormalsTexture;
			float4x4 _viewToWorld;
			float4x4 _inverseVP;
			float4x4 _WorldToVP;

            uniform float lineWidth;
            uniform float depth_threshold;
            uniform float normal_threshold;
            uniform bool is_ortho;

            uniform bool lineAdvance = false;
            uniform float line_id_boundary_width = 1.0;
            uniform float line_depth_threshold_min = 0.5f;
            uniform float line_depth_threshold_max = 2.0f;
            uniform float line_depth_width_min = 0.5f;
            uniform float line_depth_width_max = 2.0f;
            uniform float line_angle_threshold_min = 0.5f;
            uniform float line_angle_threshold_max = 1.5f;
            uniform float line_angle_width_min = 0.5f;
            uniform float line_angle_width_max = 2.0f;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(UNITY_MATRIX_M, v.vertex).xyz;
                o.uv = v.uv;
                return o;
            }
            
            float ray_plane_intersection(float3 ray_origin, float3 ray_direction, float3 plane_position, float3 plane_normal)
            {
                float r_direction = dot(ray_direction, plane_normal);
                float r_origin = dot(ray_origin, plane_normal);
                float p_position = dot(plane_position, plane_normal);

                return (p_position - r_origin) / r_direction;
            }
            //half2 offsets[] = half2[4](
            //        half2(-1, 0),
            //        half2( 1, 0),
            //        half2( 0,-1),
            //        half2( 0, 1)
            //    );

            #define OFFSET_LENGTH 4
            LineOutput line_ex(
                float2 resolution,
                float line_width,
                int line_steps,
                int LINE_DEPTH_MODE,
                float3 view_direction,
                float2 uv
            )
            {
                LineOutput result;
                result.delta_distance = 0.0;
                result.delta_angle = 1.0;
                result.id_boundary = false;

                half2 offsets[OFFSET_LENGTH];
                offsets[0] = half2(-1, 0);
                offsets[1] = half2( 1, 0);
                offsets[2] = half2( 0,-1);
                offsets[3] = half2( 0, 1);

                //offsets[4] = half2(-1, 1);
                //offsets[5] = half2( 1,-1);
                //offsets[6] = half2(-1,-1);
                //offsets[7] = half2( 1, 1);

                float2 offset = ((float2)line_width) / resolution;

                float4 depthnormal = tex2D(_CameraDepthNormalsTexture, uv);
				float3 normal = DecodeViewNormalStereo(depthnormal);
                float3 normal_camera = mul((float3x3)UNITY_MATRIX_V, normal);

				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
                float4 position = mul(_inverseVP, float4(uv * 2.0 - 1.0, depth, 1.0));
                position /= position.w;

                float3 _id = tex2D(_ObjectIDTex, uv).rgb;
                float id = _id.x/* + _id.y + _id.z*/;


                for(int i = 0; i < /*offsets.length()*/ OFFSET_LENGTH; i++)
                {
                    
                    for(int s = 1; s <= line_steps; s++)
                    {
                        float2 sample_uv = uv + offsets[i]*offset*((float)s / (float)line_steps);

                        float3 sampled_normal = DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture, sample_uv)).xyz;
                        float sampled_depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sample_uv);
                        float4 _position = mul(_inverseVP, float4(uv * 2.0 - 1.0, depth, 1.0));
                        _position /= _position.w;
                        float3 sampled_position = mul(UNITY_MATRIX_V, _position).xyz;
                        float3 _sampled_id = tex2D(_ObjectIDTex, sample_uv).rgb;
                        float sampled_id = _sampled_id.x/* + _sampled_id.y + _sampled_id.z*/;
                        

                        float delta_distance = 0;

                        if(is_ortho)
                        {
                            //TODO: Use ray-plane intersection here too.
                            delta_distance = abs(sampled_position.z - position.z);
                            delta_distance *= dot(normal, view_direction);

                        }
                        else
                        {
                            float3 ray_origin = (float3)0;
                            float3 ray_direction = normalize(sampled_position);

                            //TODO: Improve numerical stability
                            //Sometimes the normal is almost perpendicular to the camera so expected distance is very high
                            float expected_distance = ray_plane_intersection
                            (
                                ray_origin, ray_direction,
                                position, normal_camera
                            );
                            delta_distance = abs(distance(sampled_position, ray_origin) - expected_distance);
                        }
                        if
                        (
                            LINE_DEPTH_MODE == LINE_DEPTH_MODE_ANY ||
                            LINE_DEPTH_MODE == LINE_DEPTH_MODE_NEAR && depth < sampled_depth ||
                            LINE_DEPTH_MODE == LINE_DEPTH_MODE_FAR && depth > sampled_depth
                        )
                        {
                            result.delta_distance = max(result.delta_distance, delta_distance);
                            result.delta_angle = min(result.delta_angle, dot(normal, sampled_normal));
                            result.id_boundary = result.id_boundary || sampled_id != id;
                        }
                    }
                }
                result.delta_angle = acos(result.delta_angle);
                return result;
            }

            float get_line_simple(float width,float depth_threshold, float normal_threshold, float3 viewDir, float2 uv)
            {
                LineOutput lo = line_ex(_MainTex_TexelSize.zw, width, 1, 0, viewDir, uv);
                bool li = 
                    lo.id_boundary ||
                    lo.delta_distance > depth_threshold ||
                    lo.delta_angle > normal_threshold;
                return (float)li;
            }

            float get_line_advanced(
                float id_boundary_width,
                float width,
                float min_depth_threshold, float max_depth_threshold, float min_depth_width, float max_depth_width,
                float min_angle_threshold, float max_angle_threshold, float min_angle_width, float max_angle_width, 
                float3 viewDir, float2 uv
            )
            {
                LineOutput li = line_ex(_MainTex_TexelSize.zw, width, 1, 0, viewDir, uv);
                //float _line = 0.0;
                float _line = li.id_boundary ? id_boundary_width : 0.0;
        
                if(li.delta_distance > min_depth_threshold)
                {
                    float depth = map_range_clamped(
                        li.delta_distance, 
                        min_depth_threshold, max_depth_threshold,
                        min_depth_width, max_depth_width
                    );

                    _line = max(_line, depth);
                }
                if(li.delta_angle > min_angle_threshold)
                {
                    float angle = map_range_clamped(
                        li.delta_angle, 
                        min_angle_threshold, max_angle_threshold,
                        min_angle_width, max_angle_width
                    );

                    _line = max(_line, angle);
                }
                return _line;   
            }


            float4 frag (v2f i) : SV_Target
            {
                float3 viewDir = normalize(i.worldPos.xyz - _WorldSpaceCameraPos.xyz);
                float getline;
                float4 ObjectID = tex2D(_ObjectIDTex, i.uv);
                if(lineAdvance)
                {
                    getline = get_line_advanced(
                        line_id_boundary_width,
                        lineWidth, 
                        line_depth_threshold_min, line_depth_threshold_max, line_depth_width_min, line_depth_width_max,
                        line_angle_threshold_min, line_angle_threshold_max, line_angle_width_min, line_angle_width_max,
                        viewDir, i.uv);
                    
                }
                else
                {
                    getline = get_line_simple(lineWidth, depth_threshold, normal_threshold, viewDir, i.uv);
                }

    //            // sample the texture
				//float4 depthnormal = tex2D(_CameraDepthNormalsTexture, i.uv);
				//float3 worldNormal = DecodeViewNormalStereo(depthnormal);
    //            float3 cameraNormal = mul((float3x3)UNITY_MATRIX_V, worldNormal);

                float4 col = tex2D(_MainTex, i.uv);
                col.rgb = lerp(col.rgb, lineColor.rgb, saturate(getline));

                return col;
            }
            ENDCG
        }
    }
}
