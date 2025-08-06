using UnityEngine;


[ImageEffectAllowedInSceneView]
public class RayMarcher : MonoBehaviour
{
    [SerializeField] Material mat;
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Graphics.Blit(source, destination, mat);
    }
}
