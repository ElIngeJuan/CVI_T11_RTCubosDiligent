#include "structures.fxh"
#include "RayUtils.fxh"

// Función de color aleatorio basada en el ID
float3 RandomColor(uint id)
{
    return float3(
        frac(sin(id * 12.9898) * 43758.5453),
        frac(sin((id + 17) * 78.233) * 12345.6789),
        frac(sin((id + 42) * 23.123) * 98765.4321)
    );
}

// Cálculo del color base de la superficie
float3 GetSurfaceColor(uint instanceID)
{
    return (instanceID >= 4) ? RandomColor(instanceID) * 0.8 + 0.2 : g_ConstantsCB.SphereReflectionColorMask.rgb;
}

// Lanzamos un rayo de sombra y verificamos si la superficie está en sombra
bool IsInShadow(float3 surfacePos, float3 lightDir)
{
    RayDesc shadowRay = { surfacePos + lightDir * 0.001, lightDir, 0.0, 1e20 };
    return CastShadow(shadowRay, 0).Shading > 0.0;
}

// Función principal de closest hit para calcular la iluminación y sombras
[shader("closesthit")]
void main(inout PrimaryRayPayload payload, in ProceduralGeomIntersectionAttribs attribs)
{
    float3 worldPos = WorldRayOrigin() + WorldRayDirection() * RayTCurrent();  // Posición de intersección
    float3 normal   = normalize(attribs.Normal);  // Normal en el punto de intersección
    uint   instID   = InstanceIndex();  // ID de la instancia del objeto

    // Obtiene el color base según la instancia
    float3 baseColor = GetSurfaceColor(instID);

    // Inicializa el color con la luz ambiental
    float3 color = g_ConstantsCB.AmbientColor.rgb * baseColor;

    // Calcula la iluminación difusa y las sombras
    [unroll]
    for (uint i = 0; i < NUM_LIGHTS; ++i)
    {
        float3 lightDir = normalize(g_ConstantsCB.LightPos[i].xyz - worldPos);  // Dirección de la luz
        float diffuse  = saturate(dot(normal, lightDir));  // Cálculo de la iluminación difusa

        // Verifica si el punto está en sombra
        if (IsInShadow(worldPos, lightDir))
        {
            diffuse *= 0.3;  // Atenúa la luz si está en sombra (ajusta este factor según sea necesario)
        }

        // Suma la contribución de la luz
        color += diffuse * g_ConstantsCB.LightColor[i].rgb * baseColor;
    }

    // Asigna el color final al payload
    payload.Color = float4(color, 1.0);
}
