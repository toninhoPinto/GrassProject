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

Since each grass blade is a single tri wich is front facing. This means that the back of the grass blade does not exist.

We can take advantage of the tri stips and by adding a new vertex and with the right order we can create a new triangle on the back of the existing triangle/grass blade.
(dont forget to erase the restartStrip from the previous triangle, we want the new vertex to be part of the same tri strip)

```
pIn.vertex = mul(vp, center + tangent);
pIn.grassLeafColor = _LeafBottomColor;
triStream.Append(pIn);
triStream.RestartStrip();
``` 

## Randomization

The grass blades are going to be all organized and neat. Too neat for nature.
To improve this we will change some variables randomly to make it more chaotic.

To do this we use a few noise textures that increase variability between each blade.
These could be all fused into a single texture but using different channels, I used split textures since its easier.

```
float randomHeight = (IN[0].grassHeight.r + IN[1].grassHeight.r + IN[2].grassHeight.r) / 3;
float randomWind = (IN[0].grassWind.r + IN[1].grassWind.r + IN[2].grassWind.r) / 3;
float randomAngle = (IN[0].grassOrientation.r + IN[1].grassOrientation.r + IN[2].grassOrientation.r) / 3;
float steppedValue = min(IN[0].grassStepped.r + IN[1].grassStepped.r + IN[2].grassStepped.r, 0.9);
```

Sample the texture and use the value to determine a height for that specific grass blade.


Sample the texture and use the value to determine the strength of wind on that specific blade. (Logic wise it may sound a bit weird but the purpose is to avoid having all grass blades waving in sync).


Sample the texture and use the value to determine an orientation for that specific grass blade.


Sample the texture and use the value to determine how much crushed it should be. (This will be explained further)

![](http://i.imgur.com/PG8AdnI.png)

## Movement

To add movement/wind is easier than it seems. Since each grass blade is a simple triangle, you only need to move the top vertex.

```
float4 tangent = mul((center-v0) * _Widht, rotationMatrix(normal, randomAngle * TWO_PI));

pIn.vertex = mul(vp, topVectorPosition
+ tangent * sin((center.x + center.z + randomWind + _Time) * _WindSpeed) 
);
```
Basicly you pick a vector you want the grass to wave towards. I picked the vector along the base of the grass blade with the modified orientation.

After we pick our vector, we just use a sin function to change the vector. The most important thing inside the sin function is the \_Time variable. The other three (center.x + center.z + randomWind) are purely to add variety to the grass blades.

![](http://imgur.com/9UDNrVI.gif)

## Thickness   
    
For thickness we are going to replace the 2 tris with 8 tris ( 8 vertexes thanks to tri strips).
    
![](http://i.imgur.com/0P0KiT6.png)    
    
![](http://imgur.com/heanqIu.gif)    
    
## Shading     
    
## Crushing    

From 0-1 the value means how much a grass blade should be rotated downwards, with 0 meaning pointing upwards and 1 meaning the blade is completely lying down/crushed. I do not actually use 1 to avoid z-fighting between the grass blades when they are crushed.

This can, should and hopefully will be changed to a multi color texture map. The object of a multi color map is to instead of giving a crush value, have each color map to a direction.


### Direction with Color Map

//TODO

### Replacing CPU with GPU through the use of compute shader

//TODO

