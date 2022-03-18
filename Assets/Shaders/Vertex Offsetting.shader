// https://developer.download.nvidia.com/cg/index_stdlib.html

Shader "Unlit/Vertex Offsetting"
{
    Properties {
        _WaveAmp ("WaveAmplitude", Range(0, 1)) = 0.1
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

            float _WaveAmp;

            struct MeshData {
                float4 vertex : POSITION; // Vertex position
                float3 normals : NORMAL; // Normals direction of the vertices
                float2 uv0 : TEXCOORD0; // Uv0 diffuse/normal map textures (obs: uvs's can have float4 data)
            };

            struct Interpolators {
                float4 vertex : SV_POSITION; // Clip space position of each vertex
                float3 normal : TEXCOORD0; // It doens't neccessraly needs to be a normal, just a Vector3
                float2 uv0 : TEXCOORD1; // Here we're not actually transfering uv coodinates, but just data
            };

             float InverseLerp (float a, float b, float v) {
                return (v-a) / (b-a);
            }

            float GetWave(float2 uv) {
                float2 uvsCentered = uv * 2 - 1;
                float radialdistance = length(uvsCentered);
                
                //return float4(radialdistance.xxx, 1);

                // create a moving zig-zag pattern
                float zizZagIntensity = 0.01;
                float xOffset = cos(uv.x * TAU * 8) * zizZagIntensity;

                // (Unity Variable) _Time.y = Time in seconds
                float wave = cos((radialdistance + xOffset - _Time.y * 0.1) * TAU * 5) * 0.5 + 0.5;
                float wave2 = cos((radialdistance - _Time.z * 0.01) * TAU * 5) * 0.5 + 0.5;
                
                wave *= 1.25-radialdistance;

                return wave * wave2; 
            }

            Interpolators vert (MeshData m) {
                Interpolators output;

                m.vertex.y = GetWave(m.uv0) * _WaveAmp;
                output.vertex = UnityObjectToClipPos(m.vertex); // Converts local space to clip space. It also makes it follow the object transform
                output.normal = UnityObjectToWorldNormal(m.normals); // Convert to world space

                // Output the uvs
                //output.uv0 = m.uv0;

                // Output uvs with scale and offsets
                //output.uv0 = (m.uv0 + _Offset) * _Scale; // just pass through

                output.uv0 = m.uv0;

                // Output the normals
                //output.normal = m.normals; // just pass through

                return output;
            }

            fixed4 frag (Interpolators i) : SV_Target {
                //return float4(i.uv0, 0, 1);

                // i.uv0 * 2 - 1; center the coordinates
                return GetWave(i.uv0);
            }

            ENDCG
        }
    }
}
