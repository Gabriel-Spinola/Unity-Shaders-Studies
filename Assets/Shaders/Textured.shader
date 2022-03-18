// https://developer.download.nvidia.com/cg/index_stdlib.html

Shader "Unlit/Vertex Textured"
{
    Properties { 
        _MainTex ("Texure", 2D) = "White" {}
    }

    SubShader 
    {
        Tags { 
            "RenderType"="Opaque" // Tag to inform the render pipeline of what type this is
        }

        Pass 
        {
            CGPROGRAM

            #pragma vertex vert // Vertex shader assigned to the vert function
            #pragma fragment frag // Same of the Vertex

            #include "UnityCG.cginc"

            #define TAU 6.28318530718

            sampler2D _MainTex;
            float4 _MainTex_ST;

            struct MeshData {
                float4 vertex : POSITION; // Vertex position
                float3 normals : NORMAL; // Normals direction of the vertices
                float2 uv : TEXCOORD0; // Uv0 diffuse/normal map textures (obs: uvs's can have float4 data)
            };

            struct Interpolators {
                float4 vertex : SV_POSITION; // Clip space position of each vertex
                float3 normal : TEXCOORD0; // It doens't neccessraly needs to be a normal, just a Vector3
                float2 uv : TEXCOORD1; // Here we're not actually transfering uv coodinates, but just data
                float3 worldPos : TEXCOORD2;
            };

            Interpolators vert (MeshData m) {
                Interpolators output;

                output.worldPos = mul(UNITY_MATRIX_M, m.vertex); // Object to World
    
                output.vertex = UnityObjectToClipPos(m.vertex);
                output.uv = TRANSFORM_TEX(m.uv, _MainTex);
                output.uv.x += _Time.y * 0.1;

                return output;
            }

            fixed4 frag (Interpolators i) : SV_Target {
                //return float4(i.worldPos.xyz, 1);

                float4 topDownProjection = float4(i.worldPos.xy, 0, 1);

                fixed4 col = tex2D(_MainTex, topDownProjection);

                return col;
            }

            ENDCG
        }
    }
}
