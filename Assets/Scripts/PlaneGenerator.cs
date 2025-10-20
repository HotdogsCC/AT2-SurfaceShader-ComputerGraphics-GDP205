using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlaneGenerator : MonoBehaviour
{
    private Mesh mesh;
    private MeshCollider meshCollider;

    private Vector3[] vertices;
    private int[] triangles;

    [SerializeField] private Vector2Int size;
    [SerializeField] private int width, depth;

    private void Start()
    {
        GeneratePlane(0);
    }

    //makes a plane with n x n verts
    public void GeneratePlane(int n)
    {
        //make a new mesh
        mesh = new Mesh();

        //assign it to the plane
        GetComponent<MeshFilter>().mesh = mesh;
        GetComponent<MeshCollider>().sharedMesh = mesh;

        //calc the total number of verts
        vertices = new Vector3[(size.x + 1) * (size.y + 1)];

        //center grid around origin
        float halfWidth = width / 2.0f;
        float halfDepth = depth / 2.0f;

        //calc distance between verts
        float dx = width / (size.x - 1);
        float dy = depth / (size.y - 1);

        int vertex = 0;

        for (int x = 0; x <= size.x; x++)
        {
            //calc new pos in x
            float a = halfWidth - x * dx;

            for(int y = 0; y <= size.y; y++)
            {
                //calc new pos in y
                float b = -halfDepth + y * dy;

                //save pos (flip y and z because unity)
                vertices[vertex] = new Vector3(a, 0.0f, b);

                //increment vertex count
                vertex++;
            }
        }

        //total indices to be generated
        triangles = new int[size.x * size.y * 6];

        //running vert and quad count
        int vert = 0;
        int quad = 0;

        //assign each triangle
        for (int y = 0; y < size.y; y++)
        {
            for (int x = 0; x < size.x; x++)
            {
                triangles[quad + 0] = vert + 0;
                triangles[quad + 1] = vert + size.x + 1;
                triangles[quad + 2] = vert + 1;

                triangles[quad + 3] = vert + 1;
                triangles[quad + 4] = vert + size.x + 1;
                triangles[quad + 5] = vert + size.x + 2;

                vert++;
                quad += 6;
            }

            vert++;
        }



        //apply the verts to the mesh
        mesh.Clear();
        mesh.vertices = vertices;
        mesh.triangles = triangles;

        mesh.RecalculateNormals();

    }
}
