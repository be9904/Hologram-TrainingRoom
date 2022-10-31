using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SimpleRotate : MonoBehaviour
{
    private Transform _transform;
    public float rotationSpeed = 50;
    
    // Start is called before the first frame update
    void Start()
    {
        _transform = GetComponent<Transform>();
    }
    
    // Update is called once per frame
    void Update()
    {
        if(_transform)
            _transform.Rotate (0,rotationSpeed*Time.deltaTime,0);
    }
}
