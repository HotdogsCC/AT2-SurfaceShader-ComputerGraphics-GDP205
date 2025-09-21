Shader "Charlie/SpikeShader"
{
    Properties
    {
        _NormalMap ("Normal Map", 2D) = "bump" {}
        _NormalStrength ("Normal Strength", Range(0, 2)) = 1
        
        [Space]
        
        //for the spikes
        _HeightMap ("Height Map", 2D) = "black" {}
        
        [Space]
        
        _OuterTexture ("Outer Texture", 2D) = "white" {}
        _InnerTexture ("Inner Texture", 2D) = "white" {}
        
        [Space]
        
        _XSpeed ("Spike X Speed", Range(-1.0, 1.0)) = 0.3
        _YSpeed ("Spike Y Speed", Range(-1.0, 1.0)) = -0.1
        
        //how fast we scroll along the height map
        _RotationSpeeds ("Rotation Speeds", Vector) = (0,0,0)
        
        [Space]
        
        //how high the spikes are
        _MaxHeight ("Max Height", Range(0.0, 1.0)) = 0.5
        
        _AmbientStrength ("Ambient Strength", Range(0.0, 1.0)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float height : TEXCOORD1; //how much extra height was added in the vert
                float3x3 TBN : TEXCOORD2;
            };

            sampler2D _NormalMap;
            float _NormalStrength;
            sampler2D _HeightMap;

            sampler2D _OuterTexture;
            sampler2D _InnerTexture;
            
            float _XSpeed;
            float _YSpeed;
            float3 _RotationSpeeds;

            float _MaxHeight;
            float _AmbientStrength;
            
            float4x4 RotationMatrix(float3 angles)
            {
                float a = _Time[0] * angles.z;
                float b = _Time[0] * angles.y;
                float y = _Time[0] * angles.x;
                return float4x4(
                    cos(a)*cos(b), cos(a)*sin(b)*sin(y) - sin(a)*cos(y), cos(a)*sin(b)*cos(y) + sin(a)*sin(y), 0,
                    sin(a)*cos(b), sin(a)*sin(b)*sin(y) + cos(a)*cos(y), sin(a)*sin(b)*cos(y) - cos(a)*sin(y), 0,
                    -sin(b), cos(b)*sin(y), cos(b)*cos(y), 0,
                    0, 0, 0, 1

                );
            }

            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = v.vertex;
                o.uv = v.uv;

                //sample the height map
                float uSample = o.uv[0] + (_Time[0] * _XSpeed);
                float vSample = o.uv[1] + (_Time[0] * _YSpeed);
                float4 heightSample = tex2Dlod(_HeightMap, float4(uSample, vSample, 0, 0));
                float height = heightSample[0];

                //add it to the height
                float3 normal = v.normal;
                normal *= height * _MaxHeight;
                o.vertex += float4(normal, 0);

                //rotate the vert and normals
                o.vertex = mul(o.vertex, RotationMatrix(_RotationSpeeds));
                o.normal = mul(v.normal, RotationMatrix(_RotationSpeeds));
                
                //apply the height
                o.vertex = UnityObjectToClipPos(o.vertex);

                //save the height
                o.height = length(normal);

                // Build tangent-to-world matrix
                float3 normalWS  = UnityObjectToWorldNormal(o.normal);
                float3 tangentWS = UnityObjectToWorldDir(v.tangent.xyz);
                float3 bitangentWS = cross(normalWS, tangentWS) * v.tangent.w;

                o.TBN = float3x3(tangentWS, bitangentWS, normalWS);
                
                return o; 
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Transform tangent-space normal to world space
                float3 tangentNormal = UnpackScaleNormal(tex2D(_NormalMap, i.uv), _NormalStrength);
                float3 normalWS = normalize(mul(i.TBN, tangentNormal));
                
                //albedo
                float height = i.height / _MaxHeight;
                fixed4 outerColour = tex2D(_OuterTexture, i.uv);
                fixed4 innerColour = tex2D(_InnerTexture, i.uv);
                float4 albedo = (outerColour * height) + (innerColour * (1 - height));

                //diffuse
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float3 lightColor = _LightColor0.rgb;
                float NdotL = saturate(dot(normalWS, lightDir));
                float3 diffuse = NdotL * lightColor;

                //ambient
                float3 ambient = _AmbientStrength * lightColor;

                //total
                float3 totalColor = (diffuse + ambient) * albedo;
                return float4(totalColor, 1.0f);
            }
            ENDHLSL
        }
    }
}
