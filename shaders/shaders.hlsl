#define SHADOW_DEPTH_BIAS 0.00005f
struct Light
{
    float4 position;
    float4 color;
};
cbuffer ConstantBuffer: register(b0)
{
    float4x4 mwpMatrix;
    float4x4 lightMatrix;
    Light light;
}
Texture2D g_texture: register(t0);
Texture2D g_shadow_map: register(t1);
SamplerState g_sampler: register(s0);
struct PSInput
{
    float4 position : SV_POSITION;
    float4 color : COLOR;
    float2 uv : TEXCOORD;
    float3 world_position : POSITION;
    float3 normal : NORMAL;
};
PSInput VSMain(float4 position : POSITION, float4 normal: NORMAL, float4 ambient : COLOR0, float4 diffuse : COLOR1,  float4 emissive : COLOR2, float4 texcoords : TEXCOORD)
{
    PSInput result;
    result.position = mul(mwpMatrix, position);
    result.color = diffuse;
    result.uv = texcoords.xy;
    result.world_position = position.xyz;
    result.normal = normal.xyz;
    return result;
}

PSInput VSShadowMap(float4 position : POSITION, float4 normal: NORMAL, float4 ambient : COLOR0, float4 diffuse : COLOR1,  float4 emissive : COLOR2, float4 texcoords : TEXCOORD)
{
    PSInput result;
    result.position = mul(lightMatrix, position);
    result.color = diffuse;
    result.uv = texcoords.xy;
    result.world_position = position.xyz;
    result.normal = normal.xyz;
    return result;
}
float GetLambertianIntensity(PSInput input, float4 light_position, float4 light_color)
{
    float3 to_light = light_position.xyz - input.world_position;
    float distance = length(to_light);
    float attenatuation = 1.f / (distance * distance + 1.f);
    return saturate(dot(input.normal, normalize(to_light))) * light_color * attenatuation;
}
float CalcUnshadowedAmount(float3 world_position)
{
    float4 light_space_position = float4(world_position, 1.f);
    light_space_position = mul(lightMatrix, light_space_position);
    light_space_position.xyz /= light_space_position.w;
    float2 vShadowTexCoord = 0.5 * light_space_position.xy + 0.5f;
    vShadowTexCoord.y = 1.f - vShadowTexCoord.y;
    float vLightSpaceDepth = light_space_position.z - SHADOW_DEPTH_BIAS;
    return (g_shadow_map.Sample(g_sampler, vShadowTexCoord) >= vLightSpaceDepth) ? 1.0f : 0.5f;
}
float4 PSMain(PSInput input) : SV_TARGET
{
    // float4 light1 = GetLambertianIntensity(input, float4(1.f, 5.f, 1.f, 1.f), float4(1.f, 0.2f, 0.2f, 1.f));
    // float4 light2 = GetLambertianIntensity(input, float4(-1.f, 1.f, 1.f, 1.f), float4(0.2f, 1.f, 0.2f, 1.f));
    return input.color * CalcUnshadowedAmount(input.world_position) * (0.5f + 0.5f * GetLambertianIntensity(input, light.position, light.color));
}
float4 PSMain_texture(PSInput input) : SV_TARGET
{
    // float4 light1 = GetLambertianIntensity(input, float4(1.f, 5.f, 1.f, 1.f), float4(1.f, 0.2f, 0.2f, 1.f));
    // float4 light2 = GetLambertianIntensity(input, float4(-1.f, 1.f, 1.f, 1.f), float4(0.2f, 1.f, 0.2f, 1.f));

    // return g_texture.Sample(g_sampler, input.uv) * (0.2f + light1 + light2);
    return input.color * CalcUnshadowedAmount(input.world_position) * (0.5f + 0.5f * GetLambertianIntensity(input, light.position, light.color));

}