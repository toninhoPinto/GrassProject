Shader "Custom/Low_PolyVertexTexturePixelLighting"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}
		SubShader
	{
		Tags{ "RenderType" = "Opaque" "LightMode" = "ForwardBase" }
		LOD 100

		Pass
	{
		CGPROGRAM
		#pragma vertex vert
		#pragma geometry geom
		#pragma fragment frag
		// make fog work
		#pragma multi_compile_fog

		#include "UnityCG.cginc"

		struct appdata
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
		float3 normal : NORMAL;
	};

	struct v2g
	{
		float4 vertex : SV_POSITION;
		float4 textureColor : TEXCOORD0;
		float3 normal : NORMAL;
	};

	struct g2f
	{
		float4 vertex : SV_POSITION;
		float3 normal : NORMAL;
		float4 textureColor : TEXCOORD0;
	};

	sampler2D _MainTex;
	float4 _MainTex_ST;

	v2g vert(appdata v)
	{
		v2g o;
		o.vertex = mul(unity_ObjectToWorld, v.vertex);
		v.uv = TRANSFORM_TEX(v.uv, _MainTex);
		o.textureColor = tex2Dlod(_MainTex, float4(v.uv,0,0));
		o.normal = mul(v.normal, unity_WorldToObject);

		return o;
	}

	[maxvertexcount(3)]
	void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream) {

		float4 v0 = IN[0].vertex;
		float4 v1 = IN[1].vertex;
		float4 v2 = IN[2].vertex;

		float4x4 vp = mul(UNITY_MATRIX_MVP, unity_WorldToObject);

		g2f pIn;

		float4 triColor = (IN[0].textureColor + IN[1].textureColor + IN[2].textureColor) / 3;

		pIn.vertex = mul(vp, v0);
		pIn.textureColor = triColor;
		pIn.normal = IN[0].normal;
		triStream.Append(pIn);

		pIn.vertex = mul(vp, v1);
		pIn.textureColor = triColor;
		pIn.normal = IN[1].normal;
		triStream.Append(pIn);

		pIn.vertex = mul(vp, v2);
		pIn.textureColor = triColor;
		pIn.normal = IN[2].normal;
		triStream.Append(pIn);

	}

	fixed4 frag(g2f i) : SV_Target
	{

		fixed4 col = max(dot(i.normal, normalize(_WorldSpaceLightPos0)),0);
		col *= i.textureColor;

	return col;
	}
		ENDCG
	}
	}
}
