//modified version of http://kylehalladay.com/blog/tutorial/2017/02/21/Pencil-Sketch-Effect.html

Shader "Unlit/Stippling"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Hatch0("Hatch 0", 2D) = "white" {}
		_Hatch1("Hatch 1", 2D) = "white" {}
		_Hatch2("Hatch 2", 2D) = "white" {}
		_Hatch3("Hatch 3", 2D) = "white" {}
		_Hatch4("Hatch 4", 2D) = "white" {}
		_Hatch5("Hatch 5", 2D) = "white" {}

	}
		SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100

		Pass
		{
			//ambient, main directional light, vertex/SH lights and lightmaps
			Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM
			//vertex and fragment shader
			#pragma vertex vert
			#pragma fragment frag

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 norm : NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 nrm : TEXCOORD1;
				float3 wPos : TEXCOORD2;
			};

			//texture sampling
			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _Hatch0;
			sampler2D _Hatch1;
			sampler2D _Hatch2;
			sampler2D _Hatch3;
			sampler2D _Hatch4;
			sampler2D _Hatch5;
			float4 _LightColor0;

			//declaration of vertex structure
			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv * _MainTex_ST.xy + _MainTex_ST.zw;
				o.nrm = mul(float4(v.norm, 0.0), unity_WorldToObject).xyz;
				o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}


			//this blends between two samples of the texture, to allow for tiling the texture when you zoom in. 
			//the floored_log_dist selects powers of two based on your current distance.
			//I added a min to uv_scale because it looks awful when it tries to select less of the texture when you're far away
			//also likely too expensive to do unless you really need it. 
			fixed3 HatchingConstantScale(float2 _uv, half _intensity, float _dist) // _dist is distance from camera, multiplied by unity_CameraInvProjection[0][0]
			{
				float log2_dist = log2(_dist);

				float2 floored_log_dist = floor((log2_dist + float2(0.0, 1.0)) * 0.5) * 2.0 - float2(0.0, 1.0);
				float2 uv_scale = min(0.25, pow(2.0, floored_log_dist));

				float uv_blend = abs(frac(log2_dist * 0.5) * 2.0 - 1.0);



				float2 scaledUVA = _uv / uv_scale.x; // 16
				float2 scaledUVB = _uv / uv_scale.y; // 8 

				half3 hatch0A = tex2D(_Hatch0, scaledUVA);
				half3 hatch1A = tex2D(_Hatch1, scaledUVA);
				half3 hatch2A = tex2D(_Hatch2, scaledUVA);
				half3 hatch3A = tex2D(_Hatch3, scaledUVA);
				half3 hatch4A = tex2D(_Hatch4, scaledUVA);
				half3 hatch5A = tex2D(_Hatch5, scaledUVA);

				half3 hatch0B = tex2D(_Hatch0, scaledUVB);
				half3 hatch1B = tex2D(_Hatch1, scaledUVB);
				half3 hatch2B = tex2D(_Hatch2, scaledUVB);
				half3 hatch3B = tex2D(_Hatch3, scaledUVB);
				half3 hatch4B = tex2D(_Hatch4, scaledUVB);
				half3 hatch5B = tex2D(_Hatch5, scaledUVB);

				half3 hatch0 = lerp(hatch0A, hatch0B, uv_blend);
				half3 hatch1 = lerp(hatch1A, hatch1B, uv_blend);
				half3 hatch2 = lerp(hatch2A, hatch2B, uv_blend);
				half3 hatch3 = lerp(hatch3A, hatch3B, uv_blend);
				half3 hatch4 = lerp(hatch4A, hatch4B, uv_blend);
				half3 hatch5 = lerp(hatch5A, hatch5B, uv_blend);

				half3 overbright = max(0, _intensity - 0.25);

				half3 weightsA = saturate((_intensity * 2.0) + half3(-0, -1, -2));
				half3 weightsB = saturate((_intensity * 2.0) + half3(-3, -4, -5));

				weightsA.xy -= weightsA.yz;
				weightsA.z -= weightsB.x;
				weightsB.xy -= weightsB.yz;

				hatch0 = hatch0 * weightsB.z;
				hatch1 = hatch1 * weightsB.y;
				hatch2 = hatch2 * weightsB.x;
				hatch3 = hatch3 * weightsA.z;
				hatch4 = hatch4 * weightsA.y;
				hatch5 = hatch5 * weightsA.x;

				half3 hatching = overbright + hatch0 +
					hatch1 + hatch2 +
					hatch3 + hatch4 +
					hatch5;

				return hatching;
			}

			fixed3 Hatching(float2 _uv, half _intensity)
			{
				half3 hatch0 = tex2D(_Hatch0, _uv).rgb;
				half3 hatch1 = tex2D(_Hatch1, _uv).rgb;

				//white part
				half3 overbright = max(0, _intensity - 1.0);

				half3 weightsA = saturate((_intensity * 6.0) + half3(-0, -1, -2));
				half3 weightsB = saturate((_intensity * 6.0) + half3(-3, -4, -5));

				weightsA.xy -= weightsA.yz;
				weightsA.z -= weightsB.x;
				weightsB.xy -= weightsB.yz;

				hatch0 = hatch0 * weightsA;
				hatch1 = hatch1 * weightsB;

				half3 hatching = overbright + hatch0.r +
					hatch0.g + hatch0.b +
					hatch1.r + hatch1.g +
					hatch1.b;

				return hatching;
			}


			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 color = tex2D(_MainTex, i.uv);
				//diffuse lighting calculation
				fixed3 diffuse = color.rgb * _LightColor0.rgb * dot(_WorldSpaceLightPos0, normalize(i.nrm));

				//brightness of fragment with lighting applied
				fixed intensity = dot(diffuse, fixed3(0.2326, 0.7152, 0.0722));

				//shading with constant lighting level(tiling texture)
				color.rgb = HatchingConstantScale(i.uv * 5, intensity, distance(_WorldSpaceCameraPos.xyz, i.wPos) * unity_CameraInvProjection[0][0]);

				//shading without tiling mip map
				//color.rgb = Hatching(i.uv * 8, intensity);

					return color;
				}
				ENDCG
			}
	}
}