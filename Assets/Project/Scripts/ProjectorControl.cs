using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.VFX;

public class ProjectorControl : MonoBehaviour
{
    private const string VFXPositionPostfix = "_position";
    private const string VFXRotationPostfix = "_angles";
    private const string VFXScalePostfix = "_scale";

    public VisualEffect vfx;
    public Transform projectionPoint;
    private string vfxPositionVar;
    
    // Start is called before the first frame update
    void Start()
    {
        vfx = GetComponent<VisualEffect>();
        // var vfxPositionVar = "ProjectorPosition" + VFXPositionPostfix;
    }

    // Update is called once per frame
    void Update()
    {
        // vfx.SetVector3(vfxPositionVar, projectionPoint.position);
    }
}
