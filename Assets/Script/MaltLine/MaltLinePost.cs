using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.UI;

[RequireComponent(typeof(CameraData))]
[ExecuteInEditMode]
public class MaltLinePost : MonoBehaviour
{
    const string MALT_LINE_SHADER_NAME = "Unlit/MaltLine";
    const string OBJECT_ID_SHADER_NAME = "Unlit/ObjectID";
    Material maltLineMat;
    Material colorIDMat;

    Shader objectID;

    public bool isEnable = false;
    public CameraData cameraData;

    public Color LineColor;

    public bool lineAdvance = false;

    //Simple
    [Header("Simple:")]
    public float width = 1.0f;
    public float depth_threshold = 0.5f;
    public float normal_threshold = 1.0f;

    [Space(5)]
    [Header("Advance:")]
    //Advance
    public float line_id_boundary_width = 1.0f;

    public float line_depth_threshold_min = 0.5f;
    public float line_depth_threshold_max = 2.0f;
    public float line_depth_width_min = 0.5f;
    public float line_depth_width_max = 2.0f;

    public float line_angle_threshold_min = 0.5f;
    public float line_angle_threshold_max = 1.5f;
    public float line_angle_width_min = 0.5f;
    public float line_angle_width_max = 2.0f;

    Camera objIDCamera;

    private void OnEnable()
    {
        maltLineMat = new Material(Shader.Find(MALT_LINE_SHADER_NAME));
        objectID = Shader.Find(OBJECT_ID_SHADER_NAME);
        colorIDMat = new Material(objectID);
        cameraData = GetComponent<CameraData>();

        if(objIDCamera == null)
        {
            objIDCamera = new GameObject().AddComponent<Camera>();
            objIDCamera.CopyFrom(cameraData.cam);
            objIDCamera.transform.position = cameraData.cam.transform.position;
            objIDCamera.transform.rotation = cameraData.cam.transform.rotation;
            objIDCamera.transform.localScale = cameraData.cam.transform.localScale;
            objIDCamera.clearFlags = CameraClearFlags.Color;
            objIDCamera.backgroundColor = Color.black;
            //objIDCamera.hideFlags = HideFlags.HideAndDontSave | HideFlags.HideInInspector ;
            objIDCamera.gameObject.hideFlags = HideFlags.HideAndDontSave | HideFlags.HideInInspector;
            objIDCamera.gameObject.SetActive(false);
            objIDCamera.transform.parent = cameraData.cam.transform;
        }
    }

    private void OnDisable()
    {       
        maltLineMat = null;
        colorIDMat = null;

        if(objIDCamera != null)
        {
            Object.DestroyImmediate(objIDCamera.gameObject);
        }
    }

    [ImageEffectOpaque]
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (!maltLineMat) return;
        if (!colorIDMat) return;



        if(isEnable)
        {
            //cameraData.cam.RenderWithShader(objectID, "");
            RenderTexture idTex = RenderTexture.GetTemporary(source.descriptor);
            objIDCamera.gameObject.SetActive(true);
            objIDCamera.targetTexture = idTex;
            objIDCamera.RenderWithShader(objectID, "");
            objIDCamera.gameObject.SetActive(false);
            cameraData.cam.targetTexture = null;

            //Graphics.Blit(idTex, destination);

            maltLineMat.SetInt("is_ortho", cameraData.cam.orthographic ? 1 : 0);
            maltLineMat.SetMatrix("_viewToWorld", cameraData.Mat_ViewToWorld);
            maltLineMat.SetMatrix("_inverseVP", cameraData.Mat_inverseVP);
            maltLineMat.SetMatrix("_WorldToVP", cameraData.Mat_WorldToVP);

            maltLineMat.SetInt("lineAdvance", lineAdvance?1:0);

            maltLineMat.SetColor("lineColor", LineColor);

            maltLineMat.SetTexture("_ObjectIDTex", idTex);
            maltLineMat.SetFloat("lineWidth", width);
            maltLineMat.SetFloat("depth_threshold", depth_threshold);
            maltLineMat.SetFloat("normal_threshold", normal_threshold);

            maltLineMat.SetFloat("line_id_boundary_width", line_id_boundary_width);
            maltLineMat.SetFloat("line_depth_threshold_min", line_depth_threshold_min);
            maltLineMat.SetFloat("line_depth_threshold_max", line_depth_threshold_max);
            maltLineMat.SetFloat("line_depth_width_min", line_depth_width_min);
            maltLineMat.SetFloat("line_depth_width_max", line_depth_width_max);
            maltLineMat.SetFloat("line_angle_threshold_min", line_angle_threshold_min);
            maltLineMat.SetFloat("line_angle_threshold_max", line_angle_threshold_max);
            maltLineMat.SetFloat("line_angle_width_min", line_angle_width_min);
            maltLineMat.SetFloat("line_angle_width_max", line_angle_width_max);            

            Graphics.Blit(source, destination, maltLineMat);
            idTex.Release();

        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
