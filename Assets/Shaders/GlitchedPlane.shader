Shader "Charlie/GlitchedPlane"
{
    Properties
    {
        //normal map for this material
        _NormalMap ("Normal Map", 2D) = "bump" {}
        
        [Space]
        
        //used by the 'spikes' to push vertices up based on this map
        _HeightMap ("Height Map", 2D) = "black" {}
        
        [Space]
        
        //texture that gets displayed as the vertices are pushed up
        _OuterTexture ("Outer Texture", 2D) = "white" {}
        
        //texture that is displayed when the vertices are not pushed up
        _InnerTexture ("Inner Texture", 2D) = "white" {}
        
        [Space]
        
        //where the glitch effect can take place
        _GlitchMap ("Glitch Map", 2D) = "white" {}

        [Space]
        
        //how fast we scroll along the height map
        _XSpeed ("Spike X Speed", Range(-1.0, 1.0)) = 0.3
        _YSpeed ("Spike Y Speed", Range(-1.0, 1.0)) = -0.1
        
        [Space]
        
        //how high the spikes are
        _MaxHeight ("Max Height", Float) = 0.5
        
        //specular properties
        _SpecularStrength ("Specular Strength", Float) = 1.0
        _Shininess ("Shininess", Float) = 1.0
        _SpecularColor ("Specular Colour", Color) = (1.0, 1.0, 1.0)
        
        //the strength of the ambient light
        _AmbientStrength ("Ambient Strength", Range(0.0, 1.0)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags
            {
                "RenderType" = "Opaque"
                "RenderPipeline" = "UniversalPipeline"
            }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            //vertex pass information
            struct Attributes
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            //fragement pass information
            struct v2f
            {
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float height : TEXCOORD1; //how much extra height was added in the vert
            };

            //textures
            sampler2D _NormalMap;
            sampler2D _HeightMap;
            sampler2D _GlitchMap;
            sampler2D _OuterTexture;
            sampler2D _InnerTexture;

            //floats
            CBUFFER_START(UnityPerMaterial)
            float _XSpeed;
            float _YSpeed;

            float _MaxHeight;
            float _SpecularStrength;
            float _Shininess;
            float4 _SpecularColor;
            float _AmbientStrength;
            CBUFFER_END
            

            //vertex shader
            v2f vert (Attributes v)
            {
                v2f o;

                //grab the input vertex and uv
                o.vertex = v.vertex;
                o.uv = v.uv;
                
                //sample the glitch map
                float4 glitchSample = tex2Dlod(_GlitchMap, float4(o.uv[0], o.uv[1], 0, 0));
                
                //sample the height map
                float uSample = o.uv[0] + (_Time[0] * _XSpeed);
                float vSample = o.uv[1] + (_Time[0] * _YSpeed);
                float4 heightSample = tex2Dlod(_HeightMap, float4(uSample, vSample, 0, 0)) * glitchSample;
                float height = heightSample[0];

                //add it to the height
                float3 normal = v.normal;
                normal *= height * _MaxHeight;
                o.vertex += float4(normal, 0);
                
                //apply the height
                o.vertex = TransformObjectToHClip(o.vertex);

                //save the height
                o.height = length(normal);
                o.normal = TransformObjectToWorldNormal(v.normal);
                
                return o; 
            }

            //fragment shader
            float3 frag (v2f i) : SV_Target
            {
                //albedo
                float height = i.height / _MaxHeight;
                float4 outerColour = tex2D(_OuterTexture, i.uv);
                float4 innerColour = tex2D(_InnerTexture, i.uv);
                float4 albedo = (outerColour * height) + (innerColour * (1 - height)); //blend between outer and inner colours

                //diffuse
                float3 lightDir = GetMainLight().direction;
                float3 lightColor = GetMainLight().color;
                float NdotL = saturate(dot(i.normal, lightDir));
                float3 diffuse = NdotL * lightColor;

                //specular
                float3 viewDir = GetViewForwardDir();
                float3 halfVector = normalize(lightDir + viewDir);
                float clampedSpecValue = saturate(dot(halfVector, i.normal));
                float specularPower = pow(clampedSpecValue, _SpecularStrength * _Shininess);
                float3 specular = _SpecularColor.rgb * specularPower * lightColor;

                //ambient
                float3 ambient = _AmbientStrength * lightColor;

                //total
                return (diffuse + specular+ ambient) * albedo;
            }
            ENDHLSL
        }
    }
}
