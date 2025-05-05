#include "structures.fxh"
#include "RayUtils.fxh"

ConstantBuffer<CubeAttribs>  g_CubeAttribsCB;

// Genera un color pseudoaleatorio por ID de instancia
float3 RandomColor(uint id)
{
    return float3(
        frac(sin(id * 12.9898) * 43758.5453),
        frac(sin((id + 17) * 78.233) * 12345.6789),
        frac(sin((id + 42) * 23.123) * 98765.4321)
    );
}

[shader("closesthit")]
void main(inout PrimaryRayPayload payload, in BuiltInTriangleIntersectionAttributes attr)
{
    // C�lculo de barycentrics
    float3 barycentrics = float3(1.0 - attr.barycentrics.x - attr.barycentrics.y, attr.barycentrics.x, attr.barycentrics.y);

    // �ndices del tri�ngulo intersectado
    uint3 primitive = g_CubeAttribsCB.Primitives[PrimitiveIndex()].xyz;

    // C�lculo de normal interpolada
    float3 normal = g_CubeAttribsCB.Normals[primitive.x].xyz * barycentrics.x +
                    g_CubeAttribsCB.Normals[primitive.y].xyz * barycentrics.y +
                    g_CubeAttribsCB.Normals[primitive.z].xyz * barycentrics.z;
    normal = normalize(mul((float3x3) ObjectToWorld3x4(), normal));

    // Color base generado aleatoriamente por instancia
    float3 baseColor = RandomColor(InstanceID());

    // Posici�n del punto de intersecci�n
    float3 rayOrigin = WorldRayOrigin() + WorldRayDirection() * RayTCurrent();

    // Aplicar iluminaci�n b�sica (usa tu funci�n existente)
    payload.Color = baseColor;
    payload.Depth = RayTCurrent();
    LightingPass(payload.Color, rayOrigin, normal, payload.Recursion + 1);
}
