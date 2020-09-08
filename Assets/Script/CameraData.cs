using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
[ExecuteInEditMode]
public class CameraData : MonoBehaviour
{
    [HideInInspector]
    public Camera cam;

    [HideInInspector]
    public Matrix4x4 Mat_projection;
    [HideInInspector]
    public Matrix4x4 Mat_inverseVP;
    [HideInInspector]
    public Matrix4x4 Mat_WorldToVP;
    [HideInInspector]
    public Matrix4x4 Mat_ViewToWorld;
    [HideInInspector]
    public Matrix4x4 Mat_Viewer;
    [HideInInspector]
    public Matrix4x4 Mat_inv_projection;

    //上一帧的数据
    [HideInInspector]
    public Matrix4x4 prv_Mat_projection;
    [HideInInspector]
    public Matrix4x4 prv_Mat_inverseVP;
    [HideInInspector]
    public Matrix4x4 prv_Mat_WorldToVP;
    [HideInInspector]
    public Matrix4x4 prv_Mat_ViewToWorld;
    [HideInInspector]
    public Matrix4x4 prv_Mat_Viewer;

    private void Awake()
    {
        TryGetComponent(out cam);
        GetCurrentCamData();
        SetToPrvData();
    }

    /// <summary>
    /// 获取当前帧矩阵
    /// </summary>
    void GetCurrentCamData()
    {
        Mat_projection = GL.GetGPUProjectionMatrix(cam.projectionMatrix, false);
        Mat_Viewer = cam.worldToCameraMatrix;
        Mat_WorldToVP = Mat_projection * cam.worldToCameraMatrix;
        Mat_inverseVP = Matrix4x4.Inverse(Mat_projection * cam.worldToCameraMatrix);
        Mat_ViewToWorld = cam.cameraToWorldMatrix;
        Mat_inv_projection = Matrix4x4.Inverse(Mat_projection);
    }

    /// <summary>
    /// 将当前帧矩阵保存为上一帧矩阵
    /// </summary>
    void SetToPrvData()
    {
        prv_Mat_projection = Mat_projection;
        prv_Mat_inverseVP = Mat_inverseVP;
        prv_Mat_WorldToVP = Mat_WorldToVP;
        prv_Mat_ViewToWorld = Mat_ViewToWorld;
        prv_Mat_Viewer = Mat_Viewer;
    }

    // Update is called once per frame
    void Update()
    {
        if (!cam) return;

        SetToPrvData();
        GetCurrentCamData();
    }


}
