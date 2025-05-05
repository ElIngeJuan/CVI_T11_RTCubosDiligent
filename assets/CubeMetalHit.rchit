#include "structures.fxh"
#include "RayUtils.fxh"

ConstantBuffer<CubeAttribs> g_CubeAttribsCB;

[shader("closesthit")]
void main(inout PrimaryRayPayload payload, in BuiltInTriangleIntersectionAttributes attr)
{
    // Barycentrics para interpolación
    float3 barycentrics = float3(1.0 - attr.barycentrics.x - attr.barycentrics.y, attr.barycentrics.x, attr.barycentrics.y);

    // Índices del triángulo intersectado
    uint3 primitive = g_CubeAttribsCB.Primitives[PrimitiveIndex()].xyz;

    // Cálculo de normal interpolada del triángulo
    float3 normal = g_CubeAttribsCB.Normals[primitive.x] * barycentrics.x +
                    g_CubeAttribsCB.Normals[primitive.y] * barycentrics.y +
                    g_CubeAttribsCB.Normals[primitive.z] * barycentrics.z;

    // Transformar la normal al espacio mundial
    normal = normalize(mul((float3x3) ObjectToWorld3x4(), normal));

    // Dirección reflejada
    float3 rayDir = reflect(WorldRayDirection(), normal);

    // Construcción del nuevo rayo
    RayDesc ray;
    ray.Origin = WorldRayOrigin() + WorldRayDirection() * RayTCurrent() + normal * SMALL_OFFSET;
    ray.TMin   = 0.0;
    ray.TMax   = 100.0;

    // Reflexión borrosa
    float3 color = float3(0.0, 0.0, 0.0);
    const int ReflBlur = payload.Recursion > 1 ? 1 : g_ConstantsCB.SphereReflectionBlur;

    for (int j = 0; j < ReflBlur; ++j)
    {
        float2 offset = float2(g_ConstantsCB.DiscPoints[j / 2][(j % 2) * 2], g_ConstantsCB.DiscPoints[j / 2][(j % 2) * 2 + 1]);
        ray.Direction = DirectionWithinCone(rayDir, offset * 0.01);
        color += CastPrimaryRay(ray, payload.Recursion + 1).Color;
    }

    color /= float(ReflBlur);

    // Aplicar máscara de color a la reflexión
    color *= g_ConstantsCB.SphereReflectionColorMask;

    payload.Color = color;
    payload.Depth = RayTCurrent();
}
