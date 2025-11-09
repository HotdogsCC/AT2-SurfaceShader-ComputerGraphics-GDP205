using Palmmedia.ReportGenerator.Core.Reporting.Builders;
using UnityEngine;

public class PlaneManager : MonoBehaviour
{
    //reference to the high poly plane in the scene 
    [SerializeField] private GameObject highPolyPlane;
    //reference to the low poly plane in the scene 
    [SerializeField] private GameObject lowPolyPlane;
    
    //reference to the texture drawer in the high poly plane
    private TextureDrawer highPolyTextureDrawer;
    //reference to the texture drawer in the low poly plane
    private TextureDrawer lowPolyTextureDrawer;
    
    //defines which plane is enabled
    private bool isHighResEnabled = false;

    private void Start()
    {
        //set the texture drawers
        highPolyTextureDrawer = highPolyPlane.GetComponent<TextureDrawer>();
        lowPolyTextureDrawer = lowPolyPlane.GetComponent<TextureDrawer>();
    }

    //turns on the high poly plane
    public void EnableHighPolyPlane()
    {
        isHighResEnabled = true;
        
        lowPolyPlane.SetActive(false);
        highPolyPlane.SetActive(true);
        
        ResetPlane();
    }
    
    //turns on the low poly plane
    public void EnableLowPolyPlane()
    {
        isHighResEnabled = false;
        
        highPolyPlane.SetActive(false);
        lowPolyPlane.SetActive(true);
        
        ResetPlane();
    }

    public void ResetPlane()
    {
        //figure out which one is enabled and reset their colours
        if (isHighResEnabled)
        {
            highPolyTextureDrawer.ResetColours();
        }
        else
        {
            lowPolyTextureDrawer.ResetColours();
        }
    }

}
