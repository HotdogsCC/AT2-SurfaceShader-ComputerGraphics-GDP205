Shader "Charlie/SpikeShader"
{
    Properties
    {
        _HeightMap ("Height Map", 2D) = "black" {}
        [NoScaleOffset] _NormalTex("Normal Map", 2D) = "bump" {}
        
        [Space]
        
        _OuterColour ("Outer Color", Color) = (1, 0, 0, 1)
        _InnerColour ("Inner Color", Color) = (0, 0, 0, 1)
        
        [Space]
        
        _XSpeed ("Spike X Speed", Range(-1.0, 1.0)) = 0.3
        _YSpeed ("Spike Y Speed", Range(-1.0, 1.0)) = -0.1
        
        _RotationSpeeds ("Rotation Speeds", Vector) = (0,0,0)
        
        [Space]
        
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
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float height : TEXCOORD1; //how much extra height was added in the vert
            };
            
            sampler2D _HeightMap;
            sampler2D _NormalTex;

            float4 _OuterColour;
            float4 _InnerColour;
            
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

                //update the tangent
                o.tangent = mul(v.tangent, RotationMatrix(_RotationSpeeds));
                //o.tangent = float4(UnityObjectToWorldDir(o.tangent.xyz), o.tangent.w);
                
                //apply the height
                o.vertex = UnityObjectToClipPos(o.vertex);

                //save the height
                o.height = length(normal);
                
                return o; 
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //apply normal map
                i.normal = UnpackScaleNormal(tex2D(_NormalTex, i.uv), 0.25);
                i.normal = i.normal.xzy;
                i.normal = normalize(i.normal);
                float3 biTangent = cross(i.normal, i.tangent.xzy) * i.tangent.w;
                i.normal = normalize(i.normal.x * i.tangent +
                                        i.normal.y * i.normal +
                                        i.normal.z * biTangent);


                
                //albedo
                float height = i.height / _MaxHeight;
                float4 albedo = (_OuterColour * height) + (_InnerColour * (1 - height));

                //diffuse
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float3 lightColor = _LightColor0.rgb;
                float3 diffuse = saturate(dot(lightDir, i.normal)) * lightColor;

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
