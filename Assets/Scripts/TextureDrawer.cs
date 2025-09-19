using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TextureDrawer : MonoBehaviour
{
    private static readonly int GlitchMap = Shader.PropertyToID("_GlitchMap");
    public int textureSize = 512;
    public int brushSize = 16;
    public Color brushColor = Color.white;

    private Texture2D paintTex;
    private Renderer rend;

    void Start()
    {
        rend = GetComponent<Renderer>();

        // Create a black texture
        paintTex = new Texture2D(textureSize, textureSize, TextureFormat.RGBA32, false);
        ResetColours();

        rend.material.SetTexture(GlitchMap, paintTex);

        // Make sure the cube has a collider
        if (GetComponent<Collider>() == null)
            gameObject.AddComponent<MeshCollider>();
    }

    void Update()
    {
        //draws
        if (Input.GetMouseButton(0))
        {
            Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
            if (Physics.Raycast(ray, out RaycastHit hit))
            {
                Paint(hit.textureCoord); 
            }
        }
        
        //reset
        if (Input.GetKeyDown(KeyCode.Space))
        {
            ResetColours();
        }
    }

    void ResetColours()
    {
        Color[] cols = new Color[textureSize * textureSize];
        for (int i = 0; i < cols.Length; i++) cols[i] = Color.black;
        paintTex.SetPixels(cols);
        paintTex.Apply();
    }
    
    void Paint(Vector2 uv)
    {
        int x = (int)(uv.x * textureSize);
        int y = (int)(uv.y * textureSize);

        for (int i = -brushSize; i < brushSize; i++)
        {
            for (int j = -brushSize; j < brushSize; j++)
            {
                int px = x + i;
                int py = y + j;
                if (px >= 0 && px < textureSize && py >= 0 && py < textureSize)
                {
                    float dist = Vector2.Distance(new Vector2(px, py), new Vector2(x, y));
                    if (dist < brushSize) // circular brush
                        paintTex.SetPixel(px, py, brushColor);
                }
            }
        }
        paintTex.Apply();
    }
}
