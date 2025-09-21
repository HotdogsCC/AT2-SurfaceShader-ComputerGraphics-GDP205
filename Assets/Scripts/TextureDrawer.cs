using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TextureDrawer : MonoBehaviour
{
    //the var in the shader that contains the glitch map
    private static readonly int GlitchMap = Shader.PropertyToID("_GlitchMap");
    
    //dimensions of the texture
    public int textureSize = 512;
    
    //radius of effect
    public int brushSize = 16;
    
    //colour of the brush we paint with
    public Color brushColor = Color.white;

    //the texture we will write to
    private Texture2D paintTex;
    
    //the renderer of this game object
    private Renderer rend;

    void Start()
    {
        //get the renderer
        rend = GetComponent<Renderer>();

        //create a black texture
        paintTex = new Texture2D(textureSize, textureSize, TextureFormat.RGBA32, false);
        ResetColours();

        //set the glitch map of this plane to our new texture
        rend.material.SetTexture(GlitchMap, paintTex);

        //make sure the mesh has a collider
        if (GetComponent<Collider>() == null)
            gameObject.AddComponent<MeshCollider>();
    }

    void Update()
    {
        //on left click
        if (Input.GetMouseButton(0))
        {
            //figure out where the mouse lands
            Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
            if (Physics.Raycast(ray, out RaycastHit hit))
            {
                //draw on the texture
                Paint(hit.textureCoord); 
            }
        }
        
        //reset on space
        if (Input.GetKeyDown(KeyCode.Space))
        {
            ResetColours();
        }
    }

    //makes the texture go back to black
    void ResetColours()
    {
        Color[] cols = new Color[textureSize * textureSize];
        for (int i = 0; i < cols.Length; i++) cols[i] = Color.black;
        paintTex.SetPixels(cols);
        paintTex.Apply();
    }
    
    //draws in the surrounding areas on the texture
    void Paint(Vector2 uv)
    {
        //dimensions on the mesh
        int x = (int)(uv.x * textureSize);
        int y = (int)(uv.y * textureSize);

        //draw a circle
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
        
        //apply our new texture
        paintTex.Apply();
    }
}
