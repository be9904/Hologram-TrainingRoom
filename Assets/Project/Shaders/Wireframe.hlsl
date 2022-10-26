#include "WireframeInput.hlsl"

void InitializeFragmentNormal(inout v2f i)
{
    float3 dpdx = ddx(i.worldPos);
    float3 dpdy = ddy(i.worldPos);

    i.normal = normalize(cross(dpdy, dpdx));
}