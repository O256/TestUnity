Shader "Hidden/Blur" {
    Properties {
        _MainTex ("Texture", 2D) = "white" { }
        _BlurIntensity ("Blur Intensity", Range(0, 12)) = 10 //模糊强度

    }
    SubShader {
        Tags { "Queue" = "Transparent" } // 设置渲染队列为透明渲染队列
        Blend SrcAlpha OneMinusSrcAlpha // 设置混合模式为源颜色*源颜色的alpha值+目标颜色*1-源颜色的alpha值

        Pass { //第一个Pass用于绘制模糊效果
            CGPROGRAM //使用CG语言编写Shader
            #pragma vertex vert //指定顶点着色器函数
            #pragma fragment frag //指定片元着色器函数

            #include "UnityCG.cginc" //包含Unity的内置函数库

            sampler2D _MainTex; //纹理属性
            half _BlurIntensity; //模糊强度属性

            struct appdata { //定义输入结构体，q：这个结构体结构是固定的吗？a：是的，这个结构体是固定的，Unity会自动识别这个结构体，然后将顶点数据传递给这个结构体。
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                fixed4 color : COLOR;
            };

            struct v2f { //定义输出结构体
                float2 uv : TEXCOORD0; //纹理坐标
                float4 vertex : SV_POSITION; //顶点坐标，SV_POSITION表示这个变量是顶点坐标，这个变量会被传递给像素着色器，q: 会做插值吗？a: 会做插值
                fixed4 color : COLOR; //顶点颜色
            };

            //计算高斯模糊中的高斯函数的值的函数
            half BlurHD_G(half bhqp, half x) {//bhqp是一个影响高斯函数形状的参数，而x则是自变量
                return exp( - (x * x) / (2.0 * bhqp * bhqp));//exp表示自然指数函数,计算e的x次幂 -(x*x)/(2.0*bhqp*bhqp):这是高斯函数的指数部分
            }

            //实现了高斯模糊的功能
            //uv表示当前像素的纹理坐标，source是输入纹理，Intensity是模糊的强度，xScale和yScale分别表示水平和垂直方向的缩放比例。
            half4 BlurHD(half2 uv, sampler2D source, half Intensity, half xScale, half yScale) {
                int iterations = 16;//定义了模糊的迭代次数，即在模糊过程中采样的次数
                int halfIterations = iterations / 2;//计算迭代次数的一半，用于确定模糊核的中心位置
                half sigmaX = 0.1 + Intensity * 0.5;//计算水平和垂直方向的高斯模糊的标准差。Intensity参数用于调整模糊的强度，越大则模糊程度越高
                half sigmaY = sigmaX;
                half total = 0.0;//初始化总权重
                half4 ret = half4(0, 0, 0, 0);//初始化模糊结果
                for (int iy = 0; iy < iterations; ++iy) {//内层循环遍历水平方向的迭代次数
                    half fy = BlurHD_G(sigmaY, half(iy) - half(halfIterations));//计算当前水平方向的高斯权重
                    half offsetY = half(iy - halfIterations) * 0.00390625 * xScale;//计算当前像素在纹理坐标中的偏移量
                    for (int ix = 0; ix < iterations; ++ix) {////内层循环遍历垂直方向的迭代次数
                        half fx = BlurHD_G(sigmaX, half(ix) - half(halfIterations));//计算当前像素在纹理坐标中的水平偏移量
                        half offsetX = half(ix - halfIterations) * 0.00390625 * yScale;//计算当前像素在纹理坐标中的水平偏移量
                        total += fx * fy;//累加当前像素的权重
                        ret += tex2D(source, uv + half2(offsetX, offsetY)) * fx * fy;//根据当前像素的权重，采样输入纹理，计算模糊结果。
                    }
                }
                return ret / total;//返回最终的模糊结果，除以总权重以归一化结果。
            }

            v2f vert(appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.color = v.color;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                fixed4 col = tex2D(_MainTex, i.uv);
                col = BlurHD(i.uv, _MainTex, _BlurIntensity, 1, 1) * i.color;
                return col;
            }
            ENDCG
        }
    }
}