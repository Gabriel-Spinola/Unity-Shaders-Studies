// https://developer.download.nvidia.com/cg/index_stdlib.html

Shader "Unlit/ShaderT"
{
    Properties {
        _Color ("Color", Color) = (1, 1, 1, 1)
        _ColorStart ("Color A", Range(0, 1)) = 0
        _ColorEnd ("Color B", Range(0, 1)) = 1
        _ColorA ("Color A", Color) = (1, 1, 1, 1)
        _ColorB ("Color B", Color) = (1, 1, 1, 1)
        _Scale ("UV Scale", Float) = 1
        _Offset ("UV Offset", Float) = 0
    }

    SubShader 
    {
        Tags { 
            "RenderType"="Transparent" // Tag to inform the render pipeline of what type this is
            "Queue"="Transparent" // Changes the render order
        }

        Pass 
        {
            Cull Off // Just Culling; back = default, front = back but flipped
            ZWrite Off // Not Writing to the redering buffering
            ZTest LEqual // Debbuging by depth (GEqual, LEqual = default, Always)
            Blend One One // Additive

            CGPROGRAM

            #pragma vertex vert // Vertex shader assigned to the vert function
            #pragma fragment frag // Same of the Vertex

            #include "UnityCG.cginc"

            #define TAU 6.28318530718

            // bool = 0  1
            // int

            // float (32 bit float); half (16 bit float); fixed (lower precision - ~12 bit) -1 to 1.

            // float  = Vector
            // float4 = Vector4 

            // float4 -> half4 -> fixed4
            // float4x4 -> half4x4 -> fixed4x4; (Matrices, same as C#, Matrix4x4)

            // When programming for weaker platforms like mobile, is good to use 'half' for optimization
            // Basically, use floats everywhere until you have to optimize

            float4 _Color;

            float _ColorStart;
            float _ColorEnd;

            float4 _ColorA;
            float4 _ColorB;

            float _Scale;
            float _Offset;

            // Automatically filled out by unity
            struct MeshData { // Per-vertex
                float4 vertex : POSITION; // Vertex position
                float3 normals : NORMAL; // Normals direction of the vertices
                float2 uv0 : TEXCOORD0; // Uv0 diffuse/normal map textures (obs: uvs's can have float4 data)

                // Tangents in unity are float4 cause it have a fourth additional property
                // float4 tangent : TANGENT; // tangent direction (xyz) tangent sign (w)
                // float4 color: COLOR;
                // float2 uv1 : TEXCOORD1; // Uv1 lightmap coordinates (obs: uvs's can have float4 data)
            };

            // Everything we pass to fragment shader from vexter shader has to exist here
            struct Interpolators {
                float4 vertex : SV_POSITION; // Clip space position of each vertex
                float3 normal : TEXCOORD0; // It doens't neccessraly needs to be a normal, just a Vector3
                float2 uv0 : TEXCOORD1; // Here we're not actually transfering uv coodinates, but just data
                //float4 tangent : TEXCOORD1;
                //float2 randomValue : TEXCOORD2;
            };

            Interpolators vert (MeshData m) {
                Interpolators output;

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

            float InverseLerp(float a, float b, float v) {
                return (v-a) / (b-a);
            }

            fixed4 frag (Interpolators i) : SV_Target {
                /** Swizziling Vectors
                 * float4 myVec4Val;
                 * float2 myVec2Val = myVec2Val.xy; // can also use myValue.rg
                 * float2 myVec2ValSwizzlingVal = myVec4Val.yz;
                */
                
                // frac = v - floor(v)
                // if the shader repeats multiple time, it means that the value is not clamped between 0 and 1

                /*
                // saturate clamps the value between 0 and 1
                float t = saturate(InverseLerp(_ColorStart, _ColorEnd, i.uv0.y));
                // Blend between two colors based on the X UV0 coordinate
                float4 outColor = lerp(_ColorA, _ColorB, t);

                return outColor;
                */

                // Create a triangle wave in 5 fragments
                // float t = abs(frac(i.uv0.x * 5) * 2 - 1);
    
                // Create a cossine wave going through an entire period (going from 1 to -1)
                //float t = cos(i.uv0.x * TAU * 2);

                // create a moving zig-zag pattern
                float zizZagIntensity = 0.01;
                float xOffset = cos(i.uv0.x * TAU * 8) * zizZagIntensity;

                // (Unity Variable) _Time.y = Time in seconds
                float t = cos((i.uv0.y + xOffset - _Time.y * 0.1) * TAU * 5) * 0.5 + 0.5;
                t *= 1 - i.uv0.y;

                // Get the normal of the vector and check if its poiting almost enterely down or up,
                // if it is, multiply by 0, and now its invisible 
                float topBottomRemovers = (abs(i.normal.y) < 0.999);
                float waves = t * topBottomRemovers;

                float4 gradient = lerp(_ColorA, _ColorB, i.uv0.y);
                
                return gradient * waves; 
            }

            ENDCG
        }
    }
}
