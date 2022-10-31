using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.VFX;

public class ProjectorControl : MonoBehaviour
{
    public VisualEffect vfx;
    public Transform projectionPoint;
    
    // Start is called before the first frame update
    void Start()
    {
        vfx = GetComponent<VisualEffect>();
    }

    // Update is called once per frame
    void Update()
    {
    }
}
