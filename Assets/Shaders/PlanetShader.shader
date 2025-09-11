Shader "Unlit/PlanetShader"
{
    Properties
    {
        _HeightMap ("Height Map", 2D) = "black" {}
        
        [Space]
        
        _Colour ("Color", Color) = (1, 0, 0, 1)
        
        [Space]
        
        _XSpeed ("X Speed", Range(-1.0, 1.0)) = 0.3
        _YSpeed ("Y Speed", Range(-1.0, 1.0)) = -0.1
        
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

            float4 _Colour;
            
            float _XSpeed;
            float _YSpeed;

            float _MaxHeight;
            

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

                //apply the height
                o.vertex = UnityObjectToClipPos(o.vertex);

                //save the height
                o.height = length(normal);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float height = i.height / _MaxHeight;
                float4 col = _Colour * height;
                return col;
            }
            ENDHLSL
        }
    }
}
