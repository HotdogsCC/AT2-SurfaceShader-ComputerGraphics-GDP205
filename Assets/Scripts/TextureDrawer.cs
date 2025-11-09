using System;
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
    
    //the main camera
    private Camera mainCamera;

    private void OnEnable()
    {
        //get the camera
        mainCamera = Camera.main;

        //check we got the camera
        if (mainCamera == null)
        {
            Debug.LogError("Failed to find Main Camera in Texture Drawer");
        }
        
        //get the renderer
        rend = GetComponent<Renderer>();
        
        //check we got the renderer
        if (rend == null)
        {
            Debug.LogError("Failed to get Renderer in Texture Drawer");
        }

        //create a black texture
        paintTex = new Texture2D(textureSize, textureSize, TextureFormat.RGBA32, false);
        ResetColours();

        //set the glitch map of this plane to our new texture
        rend.material.SetTexture(GlitchMap, paintTex);
    }

    private void Update()
    {
        //check we have touch input
        if (Input.touchCount <= 0) return;
        
        //get touch information
        Touch touch = Input.GetTouch(0);

        //figure out where the finger is on the texture
        Ray ray = mainCamera.ScreenPointToRay(touch.position);
        if (Physics.Raycast(ray, out RaycastHit hit))
        {
            //draw on the texture
            Paint(hit.textureCoord);
        }
    }

    //makes the texture go back to black
    public void ResetColours()
    {
        Color[] cols = new Color[textureSize * textureSize];
        for (int i = 0; i < cols.Length; i++) cols[i] = Color.black;
        paintTex.SetPixels(cols);
        paintTex.Apply();
    }
    
    //draws in the surrounding areas on the texture
    private void Paint(Vector2 uv)
    {
        //dimensions on the mesh
        int x = (int)(uv.x * textureSize);
        int y = (int)(uv.y * textureSize);

        //draw a circle
        for (int i = -brushSize; i < brushSize; i++)
        {
            for (int j = -brushSize; j < brushSize; j++)
            {
                //for this pixel
                int px = x + i;
                int py = y + j;
                
                //continue if this pixel is out of range
                if (px < 0 || px >= textureSize || py < 0 || py >= textureSize) continue;
                
                //draw
                float dist = Vector2.Distance(new Vector2(px, py), new Vector2(x, y));
                if (dist < brushSize)
                {
                    paintTex.SetPixel(px, py, brushColor);
                }
            }
        }
        
        //apply our new texture
        paintTex.Apply();
    }
}
