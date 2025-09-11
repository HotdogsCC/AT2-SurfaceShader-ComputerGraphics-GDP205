Shader "Charlie/SpikeShader"
{
    Properties
    {
        _HeightMap ("Height Map", 2D) = "black" {}
        
        [Space]
        
        _OuterColour ("Outer Color", Color) = (1, 0, 0, 1)
        _InnerColour ("Inner Color", Color) = (0, 0, 0, 1)
        
        [Space]
        
        _XSpeed ("Spike X Speed", Range(-1.0, 1.0)) = 0.3
        _YSpeed ("Spike Y Speed", Range(-1.0, 1.0)) = -0.1
        
        _RotationSpeeds ("Rotation Speeds", Vector) = (0,0,0)
        
        [Space]
        
        _MaxHeight ("Max Height", float) = 0.5
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

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float height : TEXCOORD1; //how much extra height was added in the vert
            };
            
            sampler2D _HeightMap;

            float4 _OuterColour;
            float4 _InnerColour;
            
            float _XSpeed;
            float _YSpeed;
            float3 _RotationSpeeds;

            float _MaxHeight;
            
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

                //rotate the vert
                o.vertex = mul(o.vertex, RotationMatrix(_RotationSpeeds));
                
                //apply the height
                o.vertex = UnityObjectToClipPos(o.vertex);

                //save the height
                o.height = length(normal);
                
                return o; 
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float height = i.height / _MaxHeight;
                float4 col = (_OuterColour * height) + (_InnerColour * (1 - height));
                return col;
            }
            ENDHLSL
        }
    }
}
