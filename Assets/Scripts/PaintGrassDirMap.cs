using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PaintGrassDirMap : MonoBehaviour
{

    Renderer grassRenderer;
    Texture2D maskTex;
    Color[] colorsTexture;

    public int width = 64;
    public int height = 64;
    public float size = 2;

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
        if (!this.enabled)
            return;
        if (collision.gameObject.GetComponent<Rigidbody>().velocity.sqrMagnitude > 0f)
        {
            Vector3 dirInObj = grassRenderer.transform.InverseTransformVector(collision.gameObject.GetComponent<Rigidbody>().velocity);
            Vector2 dir;
            dir.x = (-dirInObj.x + 5f) / 10f;
            dir.y = (-dirInObj.z + 5f) / 10f;

            HandleOneLineAtATime(collision.contacts, dir);
        }
    }

    void HandleOnePointAtATime(ContactPoint[] contacts, Vector2 dir)
    {
        for (int i = 0; i < contacts.Length; i++)
        {
            Debug.DrawRay(contacts[i].point, Vector3.up, Color.red, 10f);
            Vector3 pointInObj = grassRenderer.transform.InverseTransformPoint(contacts[i].point);

            point.x = (-pointInObj.x + 5f) / 10f;
            point.y = (-pointInObj.z + 5f) / 10f;

            PaintTexturePos(point, dir);
        }
    }

    void HandleOneLineAtATime(ContactPoint[] contacts, Vector2 dir)
    {
        Vector2 point2 = new Vector2();
        for (int i = 0; i < contacts.Length; i++)
        {
            Debug.DrawRay(contacts[i].point, Vector3.up, Color.red, 10f);
            Vector3 pointInObj = grassRenderer.transform.InverseTransformPoint(contacts[i].point);

            point.x = (-pointInObj.x + 5f) / 10f;
            point.y = (-pointInObj.z + 5f) / 10f;

            pointInObj = grassRenderer.transform.InverseTransformPoint(contacts[(i + 1) % contacts.Length].point);

            point2.x = (-pointInObj.x + 5f) / 10f;
            point2.y = (-pointInObj.z + 5f) / 10f;

            Debug.DrawLine(contacts[i].point, contacts[(i + 1) % contacts.Length].point, Color.blue, 10f);

            PaintTextureLine(point, point2, dir, dir);
        }
    }

    //receive a uv position
    //scale it over the texture space
    //loop over color array, check where to paint
    //apply color array to the texture and then to the shader
    void PaintTexturePos(Vector2 pos, Vector2 color)
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
                // - (ipos - pos).magnitude / size;
                colorsTexture[i] += new Color(color.x, color.y, 0f);
            }
        }
        maskTex.SetPixels(colorsTexture);
        maskTex.Apply();
        grassRenderer.material.SetTexture("_SteppedTex", maskTex);
    }

    //receive 2 uv positions
    //scale them over the texture space
    //loop over color array, check where to paint
    //apply color array to the texture and then to the shader
    void PaintTextureLine(Vector2 pos, Vector2 pos2, Vector2 color, Vector2 color2)
    {
        pos.x *= width;
        pos.y *= height;

        pos2.x *= width;
        pos2.y *= height;

        Vector2 dirVector = pos2 - pos;
        Vector2 ipos = new Vector2();

        float lineSize = dirVector.sqrMagnitude;

        Vector2 iPosProjected;
        Vector2 finalColor;

        for (int i = 0; i < colorsTexture.Length; i++)
        {
            ipos.x = i % height;
            ipos.y = i / width;

            if (lineSize == 0)
            {
                iPosProjected = pos;
                finalColor = color;
            }
            else
            {
                Vector2 newVector = ipos - pos;
                float projectedSize = Vector2.Dot(newVector, dirVector) / dirVector.sqrMagnitude;

                if (projectedSize < 0f)
                {
                    iPosProjected = pos;
                    finalColor = color;
                }
                else if (projectedSize > 1f)
                {
                    iPosProjected = pos2;
                    finalColor = color2;
                }
                else
                {
                    iPosProjected = pos + projectedSize * dirVector;
                    finalColor = color * projectedSize + color2 * (1 - projectedSize);
                }

            }

            if ((ipos - iPosProjected).magnitude < size)
            {
                float newColor = (ipos - iPosProjected).magnitude / size;
                colorsTexture[i] = new Color(color.x, color.y, 1f);
            }
        }
        maskTex.SetPixels(colorsTexture);
        maskTex.Apply();
        grassRenderer.material.SetTexture("_SteppedTex", maskTex);
    }

}
