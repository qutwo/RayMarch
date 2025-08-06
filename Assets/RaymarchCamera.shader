Shader "Unlit/RaymarchCamera"
{
    Properties
    {
     
        _ObjectColor ("Object", Color) = (0,0,0,0)
        _FresnelColor ("fresnel", Color) = (0,0,0,0)
        _BGColor ("BG", Color) = (0,0,0,0)
        _LightColor ("Light", Color) = (0,0,0,0)
        _SpecularColor ("Specular", Color) = (0,0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
      

        Pass
        {
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
           
            
            #include "UnityCG.cginc"
            
            float4 _ObjectColor;
            float4 _FresnelColor;
            float4 _BGColor;
            float4 _LightColor;
            float4 _SpecularColor;
          

            struct appdata
            {
                float4 vertex : POSITION;
          
            };

            struct v2f
            {
               
                float4 vertex : SV_POSITION;
                float4 wPos : TEXCOORD1;
            };
            float smin( float a, float b, float k )
            {
                k *= 16.0/3.0;
                float h = max( k-abs(a-b), 0.0 )/k;
                return min(a,b) - h*h*h*(4.0-h)*k*(1.0/16.0);
            }
            float sdfSphere(float3 refrence, float3 centre,float r)
            {
                return length(refrence - centre)- r ;
            }
            float sdfBox( float3 refrence,float3 centre, float3 b )
            {
                float3 q = abs(refrence - centre) - b;
                return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
            }
            float sdf(float3 p)
            {
               p.z  += _Time.w*0.1;
               p.x +=   sin(_Time.w*0.1); 
               p.z += cos(_Time.w*0.1);
               p = (frac(p) - 0.5);
               // p.z += 2;
               float a = sdfSphere(p,float3(_SinTime.w*0.1,_SinTime.w*0.2,0),0.07);
               float b = sdfSphere(p,float3(_CosTime.w*0.1,_CosTime.w*0.3,0),0.07);   
               float c = sdfBox(p,float3(_CosTime.w*0.2,_CosTime.w*-0.2,0),float3(0.12,0.12,0.12));
               float d = sdfBox(p,float3(_SinTime.w*-0.2,_SinTime.w*-0.2,0),float3(0.12,0.12,0.12));
               float e = sdfBox(p,float3(_CosTime.w*-0.2,_CosTime.w*0.2,0),float3(0.12,0.12,0.12));
               float f = sdfBox(p,float3(_SinTime.w*0.2,_SinTime.w*0.2,0),float3(0.12,0.12,0.12));
               // return a;
               // return b;
               // return c;
               return smin(a,smin(b,smin(f,smin(e,smin(c,d,0.03),0.03),0.03),0.03),0.03);
            }
           float3 calcNormal(float3 p ) 
           {
                float eps = 0.0001; 
                float2 h = float2(eps,0);
                return normalize( float3(sdf(p+h.xyy) - sdf(p-h.xyy),sdf(p+h.yxy) - sdf(p-h.yxy),sdf(p+h.yyx) - sdf(p-h.yyx) ) );
           }  


            float raymarch(float2 uv)
           {
                float t = 0;
                float3 r0 = _WorldSpaceCameraPos;
                float3 rd = mul(unity_CameraInvProjection,float4(uv,0,1)).xyz;
                rd = mul(UNITY_MATRIX_I_V,float4(rd,0)).xyz;
                float3 p = float3(0,0,0);
                for(int i = 0;i<80;i++)
                {
                
                    float3 p = r0 + rd * t;
                    t += sdf(p);
                    if (t<0.1||t>10)
                    {
                        break;
                    }
                    
                }
               
                return t;
           }
           
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                
                o.wPos = mul(unity_ObjectToWorld,v.vertex);
           
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // return float4((1 - raymarch(float2((i.vertex.x - _ScreenParams.x/2)*2,(i.vertex.y-_ScreenParams.y/2)*-2))),0,0,1);
                // return float4((i.vertex.x - _ScreenParams.x/2)*2,(i.vertex.y-_ScreenParams.y/2)*2,0,1);
                // return float4(raymarch(float2((i.vertex.x - _ScreenParams.x/2)*2,(i.vertex.y-_ScreenParams.y/2)*2)),1);
                // return float4(1 -  raymarch(float2(i.uv -0.5)*2,0,0,1);
                // return float4((1 -raymarch(float2(((i.vertex.x/_ScreenParams.x)-0.5)*2,((i.vertex.y/_ScreenParams.y)-0.5)*2*_ScreenParams.y/_ScreenParams.x))*0.1),0,0,1);
                
                float2 uv = float2(((i.vertex.x/_ScreenParams.x)-0.5)*2,((i.vertex.y/_ScreenParams.y)-0.5)*2);
                
                float d = raymarch(uv);
                float3 col = _BGColor;
                if(d<10)
                {
                    float3 r0 = _WorldSpaceCameraPos;
                    float3 rd = mul(unity_CameraInvProjection,float4(uv,0,1)).xyz;
                    rd = mul(UNITY_MATRIX_I_V,float4(rd,0)).xyz;
                    float3 p = r0 + rd*d;
                    float3 N = calcNormal(p);
                    float3 V = normalize(r0-p);
                    float3 lightpos = float3(1,2,-1);
                    float3 L = normalize(lightpos - p);
                    float3 H = normalize(L+V);
                    float3 diffuseLight = saturate(dot(L,N)) * _LightColor ;
                    float3 fresnel = saturate(1- dot(V,N)) ; 
                    float3 specular = saturate(dot(H,N))  ; 
                    fresnel = pow(fresnel,5)* _FresnelColor;
                    specular = pow(specular,10)* _SpecularColor;
                    col = saturate(_ObjectColor*0.5 + diffuseLight*0.5 + fresnel*0.5 + specular *0.5) ;
                   
                }
                
                return float4(col,1);
                
                
            }
            
            ENDCG
            
               
        }
    }
}
