# GrassProject

A small geometry grass shader for gpu dynamic grass where each grass blade is an individual triangle.

disclaimer: This is my first geometry shader, I'm still learning.

## Table of Content
- [Simple Grass](#simple-grass)
- [Two Sided](#two-sided)
- [Randomization](#randomization)
- [Adding Thickness](#thickness)


## Simple Grass

The method is simple, for each triangle, get a center point (by averaging the triangles vertexes). This center point will be the origin for the grass blade.
You then need a sideways vector for the width and a upwards vector for the height.

![](http://i.imgur.com/JnVmnFP.png)

The side vector can be obtained by subtracting one of the vertices of the triangle with the center point.
The up vector can be obtained by averaging the normals of each of the triangles.

These two vectors are then multiplied with variables to allow further control.

```
		float4 normal = float4((n0 + n1 + n2) / 3,0) *_Height * randomHeight;
		float4 tangent = (center-v0) * _Widht;
```

The following step is to use this data to create the triangles.

The side vertexes are calculated by adding and subtracting the tangent vector to the center point.
The up vertex is calculated by adding the normal to the center point.
Don't forget to multiply them with the MVP matrix.

Finally we need to add some color to the grass blades.
The method i chose was to have two color properties and have them be a gradient.
This is achieved by saving one color for the two bottom vertexes and one color for the top vertex.
Then by passing it to the fragment shader, the colors are interpolated through the grass blade.

```
		g2f pIn;

		pIn.vertex = mul(vp, center + tangent);
		pIn.grassLeafColor = _LeafBottomColor;
		triStream.Append(pIn);

		pIn.vertex = mul(vp, center - tangent);
		pIn.grassLeafColor = _LeafBottomColor;
		triStream.Append(pIn);

		pIn.vertex = mul(vp, normal + center);
		pIn.grassLeafColor = _LeafTopColor;
		triStream.Append(pIn);
    triStream.RestartStrip();
    
```

Note: I dont know if one should end the strip at the end of the geometry shader, or if it even makes a difference

```
	fixed4 frag(g2f i) : SV_Target
	{
		fixed4 col = i.grassLeafColor;
		return col;
	}
```


Add a plane below the grass and BAM!

![](http://i.imgur.com/gwrzGNY.png)

You should have something like this. You will notice that each grass blade only renders in one direction, points directly up, they are all oriented the same direction,
they all have the same length and they are all static which is a bit boring.

## Two Sided

## Randomization

## Thickness   
    
## Shading     
    
    
