using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PaintGrassStepMap : MonoBehaviour {

    Renderer grassRenderer;
    Texture2D maskTex;
    Color[] colorsTexture;

    public int width = 64;
    public int height = 64;
    public int size = 2;

    Vector2 point;

    // Initialize a texture and a color array to later use as a texture map for the grass
    void Start()
    {
        grassRenderer = GetComponent<Renderer>();
        point = new Vector2();

        maskTex = new Texture2D(width, height, TextureFormat.RGBAHalf, false);
        maskTex.wrapMode = TextureWrapMode.Clamp;
        colorsTexture = maskTex.GetPixels();
        Color black = new Color(0, 0, 0, 0);
        for (int i = 0; i < colorsTexture.Length; i++)
        {
            colorsTexture[i] = black;
        }
        maskTex.SetPixels(colorsTexture);
        maskTex.Apply();
    }


    //Detect collisions, for each collision point get its position in object space
    //since the object space goes between -5 to 5, transform it into 0 to 1 which is equivalent to the uv
    void OnCollisionStay(Collision collision)
    {
        for (int i = 0; i < collision.contacts.Length; i++)
        {
            Debug.DrawRay(collision.contacts[i].point, Vector3.up*4, Color.red, 10f);
            Vector3 pointInObj = grassRenderer.transform.InverseTransformPoint(collision.contacts[i].point);

            point.x = (-pointInObj.x + 5f) / 10f;
            point.y = (-pointInObj.z + 5f) / 10f;
            PaintTexture(point);
        }
    }

    //receive a uv position
    //scale it over the texture space
    //loop over color array, check where to paint
    //apply color array to the texture and then to the shader
    void PaintTexture(Vector2 pos)
    {
        pos.x *= width;
        pos.y *= height;
        Vector2 ipos = new Vector2();
        for (int i = 0; i < colorsTexture.Length; i++)
        {
            ipos.x = i % height;
            ipos.y = i / width;
            if ((ipos - pos).magnitude < size)
            {
                float newColor = .15f;  // - (ipos - pos).magnitude / size;
                colorsTexture[i] += new Color(newColor, newColor, newColor);
            }
        }
        maskTex.SetPixels(colorsTexture);
        maskTex.Apply();
        grassRenderer.material.SetTexture("_SteppedTex", maskTex);
    }

}
