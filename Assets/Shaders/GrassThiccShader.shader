Shader "Custom/GrassThiccShader"
{
	Properties
	{
		_MainTex("Grass Heigh Map", 2D) = "white" {}
		_OrienTex("Grass Orientation Map", 2D) = "white" {}
		_WavyTex("Wind Map", 2D) = "white" {}
		_SteppedTex("Grass Stepped", 2D) = "black" {}

		_Height("Grass Height", Range(0,10)) = 0.5
		_Widht("Grass Width", Range(0,2)) = 0.5
		_Thickness("Grass Thickness", Range(0,1)) = 0.5
		_WindSpeed("Wind Speed", Range(0,5)) = 0.5
		_LeafBottomColor("GrassLeaves Bottom Color", Color) = (0, .5, 0, 1) 
		_LeafTopColor("GrassLeaves Top Color", Color) = (0, 1, 0, 1)
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
		float3 normal : NORMAL;
		float4 grassOrientation : TEXCOORD0;
		float4 grassStepped : TEXCOORD1;
		float4 grassHeight : TEXCOORD2;
		float4 grassWind : TEXCOORD3;
	};

	struct g2f
	{
		float4 vertex : SV_POSITION;
		float4 grassLeafColor : COLOR;
	};

	sampler2D _MainTex;
	sampler2D _SteppedTex;
	sampler2D _OrienTex;
	sampler2D _WavyTex;
	float4 _MainTex_ST;
	float _Height;
	float _GrassRotation;
	float _Widht;
	float _Thickness;
	float4 _LeafBottomColor;
	float4 _LeafTopColor;
	float _WindSpeed;

	//vertex shader, simply sample the shader at each vertex location and move along data to the geometry shader
	v2g vert(appdata v)
	{
		v2g o;
		o.vertex = mul(unity_ObjectToWorld, v.vertex);
		v.uv = TRANSFORM_TEX(v.uv, _MainTex);
		o.normal = mul(v.normal, unity_WorldToObject);

		o.grassOrientation = tex2Dlod(_OrienTex, float4(v.uv, 0, 0));
		o.grassHeight = tex2Dlod(_MainTex, float4(v.uv, 0, 0));
		o.grassStepped = tex2Dlod(_SteppedTex, float4(v.uv, 0, 0));
		o.grassWind = tex2Dlod(_WavyTex, float4(v.uv, 0, 0));
		
		return o;
	}


	//rotation function copied from the web, should create a matrix that rotates a vector
	float4x4 rotationMatrix(float4 axis, float angle)
	{
		axis = normalize(axis);
		float s = sin(angle);
		float c = cos(angle);
		float oc = 1.0 - c;

		return float4x4(oc * axis.x * axis.x + c,			oc * axis.x * axis.y - axis.z * s,	oc * axis.z * axis.x + axis.y * s,	0.0,
						oc * axis.x * axis.y + axis.z * s,	oc * axis.y * axis.y + c,			oc * axis.y * axis.z - axis.x * s,	0.0,
						oc * axis.z * axis.x - axis.y * s,	oc * axis.y * axis.z + axis.x * s,	oc * axis.z * axis.z + c,			0.0,
						0.0,								0.0,								0.0,								1.0);
	}

	[maxvertexcount(12)]
	void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream) {

		float4 v0 = IN[0].vertex;
		float4 v1 = IN[1].vertex;
		float4 v2 = IN[2].vertex;

		float3 n0 = IN[0].normal;
		float3 n1 = IN[1].normal;
		float3 n2 = IN[2].normal;
		const float HALF_PI = 3.14159 / 2;
		const float TWO_PI = 3.14159 * 2;

		float4x4 vp = mul(UNITY_MATRIX_MVP, unity_WorldToObject);

		//noise textures that increase variability between each blade
		//these could be all fused into a single texture but different channels, just think of the saving on the texture lookups
		float randomHeight = (IN[0].grassHeight.r + IN[1].grassHeight.r + IN[2].grassHeight.r) / 3;
		float randomWind = (IN[0].grassWind.r + IN[1].grassWind.r + IN[2].grassWind.r) / 3;
		float randomAngle = (IN[0].grassOrientation.r + IN[1].grassOrientation.r + IN[2].grassOrientation.r) / 3;
		float steppedValue = min(IN[0].grassStepped.r + IN[1].grassStepped.r + IN[2].grassStepped.r, 0.9);

		//center will be the bottom of each grass blade
		float4 center = (v0 + v1 + v2) / 3;
		//basicly the up vector
		float4 normal = float4((n0 + n1 + n2) / 3,0) *_Height * randomHeight;
		//basicly the bottom vector that defines both the width and the orientation of the triangle/blade
		float4 tangent = mul((center - v0) * _Widht, rotationMatrix(normal, randomAngle * TWO_PI));
		//create a vector perpendicular to the tangent and the normal to give the blades thickness
		float4 thickness = float4(normalize(cross(normal,tangent))*_Thickness, 0);

		//first tri
		g2f pIn;
		
		pIn.vertex = mul(vp, center - tangent);
		pIn.grassLeafColor = _LeafBottomColor;
		triStream.Append(pIn);

		//top vertex of the triangle, multiply the normal vector with a rotation matrix create with the crush texture map
		//also add a sideways vector and multiply it with a sin function in order to animate wind
		pIn.vertex = mul(vp, (mul(normal, rotationMatrix(tangent, steppedValue * HALF_PI)) + center) + tangent * sin((center.x + center.z + randomWind + _Time) * _WindSpeed) );
		pIn.grassLeafColor = _LeafTopColor;
		triStream.Append(pIn);

		pIn.vertex = mul(vp, center + thickness);
		pIn.grassLeafColor = _LeafBottomColor;
		triStream.Append(pIn);

		//take advantage of triangle strip
		pIn.vertex = mul(vp, center + tangent);
		pIn.grassLeafColor = _LeafBottomColor;
		triStream.Append(pIn);
		triStream.RestartStrip();
		

		//backside triangles

		pIn.vertex = mul(vp, center - tangent);
		pIn.grassLeafColor = _LeafBottomColor;
		triStream.Append(pIn);

		pIn.vertex = mul(vp, center - thickness);
		pIn.grassLeafColor = _LeafBottomColor;
		triStream.Append(pIn);

		pIn.vertex = mul(vp, (mul(normal, rotationMatrix(tangent, steppedValue * HALF_PI)) + center) + tangent * sin((center.x + center.z + randomWind + _Time) * _WindSpeed));
		pIn.grassLeafColor = _LeafTopColor;
		triStream.Append(pIn);

		//take advantage of triangle strip
		pIn.vertex = mul(vp, center + tangent);
		pIn.grassLeafColor = _LeafBottomColor;
		triStream.Append(pIn);
		triStream.RestartStrip();

	}

	fixed4 frag(g2f i) : SV_Target
	{
		fixed4 col = i.grassLeafColor;
		return col;
	}


		ENDCG
	}
	}
}
