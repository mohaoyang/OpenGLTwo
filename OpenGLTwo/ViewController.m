//
//  ViewController.m
//  OpenGLTwo
//
//  Created by jshtmhy on 2017/8/16.
//  Copyright © 2017年 jshtmhy. All rights reserved.
//
/** 学习目标 绘制移动的球体
 * 第一步：创建GLKViewController控制器（在里面实现方法）
 * 第二步：创建EAGContext 跟踪所有状态，命令和资源
 * 第三步：生成球体的顶点坐标和颜色数据
 * 第四步：清楚命令
 * 第五步：创建投影坐标系
 * 第六步：创建对象坐标
 * 第七步：导入顶点数据
 *
 **/

#import "ViewController.h"
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@interface ViewController ()
@property (nonatomic,strong) EAGLContext *eagContext;

@end

@implementation ViewController {
    GLfloat *_vertextArray;
    GLubyte *_colorsArray;
    
    GLint m_Stacks,m_Slices;
    GLfloat m_Scale;
    GLfloat m_Squash;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createEagContext];
    [self configure];
    [self calculate];
    [self setClipping];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self clear];
    [self initModelViewMatrix];
    [self loadVertexData];
    [self loadColorBuffer];
    [self draw];
}

/**
 *  创建EAGContext 跟踪所有状态,命令和资源
 */
- (void)createEagContext{
    self.eagContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES1];
    [EAGLContext setCurrentContext:self.eagContext];
}
/**
 *  配置view
 */

- (void)configure{
    GLKView *view = (GLKView*)self.view;
    
    /*
        GLKViewDrawableDepthFormatNone = 0, 不开启
        GLKViewDrawableDepthFormat16,       消耗资源少，但是当对象非常接近彼此时，可能存在渲染问题
        GLKViewDrawableDepthFormat24,
     */
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24; //开启深度缓冲区 深度缓冲区保证离观察者更近的物体”盖住”远的物体.
    view.context = self.eagContext;
    
    
    
}

/**
 *  清除
 */
-(void)clear{
    glEnable(GL_DEPTH_TEST); //启用深度测试 根据坐标的远近自动隐藏被遮住的图形（材料）
    glClearColor(1, 1, 1, 0.1);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    
}

/**
 *  创建投影坐标
 */
/*
   这个是投影的意思，就是要对投影相关进行操作，也就是把物体投影到一个平面上，就像我们照相一样，把3维物体投到2维的平面上。这样，接
   下来的语句可以是跟透视相关的函数，比如glFrustumf()或gluPerspective()；
 */
- (void)initProjectionMatrix{
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity(); //是将以前的改变都清掉
}

/**
 *  创建物体坐标
 */

-(void)initModelViewMatrix{
    
    
    glMatrixMode(GL_MODELVIEW); //对模型视景的操作，接下来的语句描绘一个以模型为基础的适应，这样来设置参数
    glLoadIdentity();
    static GLfloat transY = 0.0;
    static GLfloat z=-2;
    static CGFloat scale = 1;
    static BOOL isBig = true;
    
    // 使球体不断缩小放大
    if (isBig){
        scale += 0.01;
    }else{
        scale -= 0.01;
    }
    if (scale>=1.5){
        isBig = false;
    }
    if (scale<=0.5){
        isBig = true;
    }
    //1
    static GLfloat spinX=0;
    static GLfloat spinY=0;
    
    /*
        沿X轴正方向平移x个单位(x是有符号数)
        沿Y轴正方向平移y个单位(y是有符号数)
        沿Z轴正方向平移z个单位(z是有符号数)
     */
    glTranslatef(0.0, (GLfloat)(sinf(transY)/2.0), z);
    glRotatef(spinY, 0.0, 1.0, 0.0);  //以点(0,0,0)到点(x,y,z)为轴，旋转spinY角度；
    glRotatef(spinX, 1.0, 0.0, 0.0);
    glScalef(scale, scale, scale); //将模型按x,y,z方向分别拉伸了scale倍。
    
//  这三句代码开启上下左右移动
//    transY += 0.075f;
//    spinY+=.25;
//    spinX+=.25;
}
/**
 *  导出顶点坐标
 *  glVertexPointer 第一个参数:每个顶点数据的个数,第二个参数,顶点数据的数据类型,第三个偏移量，第四个顶点数组地址
 */
- (void)loadVertexData{
     glEnableClientState(GL_VERTEX_ARRAY);//在使用顶点数组时,必须先调用glEnableClientState开启顶点数组功能,在不用的时候调用glDisableClientState来禁用
    /*
        glVertexPointer (GLint size, GLenum type, GLsizei stride, const GLvoid *pointer)
         size:
         每个顶点有几个数指描述。必须是2，3  ，4 之一，初始值是4.
         type:
         数组中每个顶点的坐标类型。取值：GL_BYTE, GL_SHORT , GL_FIXED , GL_FLOAT,   初始值 GL_FLOAT
         stride：
         数组中每个顶点间的间隔，步长（字节位移）。取值若为0，表示数组是连续的   初始值为0
         pointer
         你定义的数组 ,存储着每个顶点的坐标值。初始值为0
     */
    glVertexPointer(3, GL_FLOAT, 0, _vertextArray); //指定数组顶点 ;绘制球体，有 x、y、z值，所以是 3
   
}

/**
 *  导入颜色数据
 */
- (void)loadColorBuffer{
    /*
        glColorPointer (GLint size, GLenum type, GLsizei stride, const GLvoid *pointer)
         size——指明每个颜色的元素数量，必须为4。
         type——指明每个矩阵中颜色元素的数据类型，允许的符号常量有GL_UNSIGNED_BYTE, GL_FIXED和GL_FLOAT，初始值为GL_FLOAT。
         stride——指明连续的点之间的位偏移，如果stride为0时，颜色被紧密挤入矩阵，初始值为0。
         pointer——指明包含颜色的缓冲区，如果pointer为null，则为设置缓冲区。
     */
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, _colorsArray); //指定颜色数据数组，而颜色是 r、g、b、a 值，所以是 4
    glEnableClientState(GL_COLOR_ARRAY);
}

/**
 *  导入索引数据
 */
-(void)draw{
    // 开启剔除面功能
    glEnable(GL_CULL_FACE);                                                             //3
    glCullFace(GL_BACK); // 剔除背面
    /*
        提供绘制功能。当采用顶点数组方式绘制图形时，使用该函数。该函数根据顶点数组中的坐标数据和指定的模式，进行绘制。
         GL_TRIANGLE_STRIP   OpenGL的使用将最开始的两个顶点出发，然后遍历每个顶点，这些顶点将使用前2个顶点一起组成球体。
         first     从数组缓存中的哪一位开始绘制，一般为0
         count，数组中顶点的数量。
     */
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (m_Slices +1)*2*(m_Stacks-1)+2);
    glDisableClientState(GL_VERTEX_ARRAY);            // 禁用顶点数组
    // free(_vertexArray);
    // free(_colorsArray);
}

/**
 *  生成球体的顶点坐标和颜色数据
 */
-(void)calculate{
    unsigned int colorIncrment=0;				//1
    unsigned int blue=0;
    unsigned int red=255;
    unsigned int green = 0;
    static int big = 1;
    static float scale = 0.0;
//    if (big){
//        scale += 0.01;
//    }else{
//        scale -= 0.01;
//    }
//    
//    
//    if (scale >= 0.5){
//        big = 0;
//    }
//    if (scale <= 0){
//        big = 1;
//    }
    m_Scale = 0.5 + scale;
    m_Slices = 100;
    m_Squash = 1;
    m_Stacks = 100;
    colorIncrment = 255/m_Stacks;					//2
    
    //vertices
    GLfloat *vPtr =  _vertextArray =
    (GLfloat*)malloc(sizeof(GLfloat) * 3 * ((m_Slices*2+2) * (m_Stacks)));	//3
    
    
    //color data
    
    GLubyte *cPtr = _colorsArray =
    (GLubyte*)malloc(sizeof(GLubyte) * 4 * ((m_Slices *2+2) * (m_Stacks)));	//4
    
    unsigned int	phiIdx, thetaIdx;
    
    //latitude
    
    for(phiIdx=0; phiIdx < m_Stacks; phiIdx++)		//5
    {
        
        float phi0 = M_PI * ((float)(phiIdx+0) * (1.0f/(float)( m_Stacks)) - 0.5f);
        float phi1 = M_PI * ((float)(phiIdx+1) * (1.0f/(float)( m_Stacks)) - 0.5f);
        float cosPhi0 = cos(phi0);			//8
        float sinPhi0 = sin(phi0);
        float cosPhi1 = cos(phi1);
        float sinPhi1 = sin(phi1);
        float cosTheta, sinTheta;
        for(thetaIdx=0; thetaIdx < m_Slices; thetaIdx++)
        {
            
            
            float theta = 2.0f*M_PI * ((float)thetaIdx) * (1.0f/(float)( m_Slices -1));
            cosTheta = cos(theta);
            sinTheta = sin(theta);
            
            
            vPtr [0] = m_Scale*cosPhi0 * cosTheta;
            vPtr [1] = m_Scale*sinPhi0*m_Squash;
            vPtr [2] = m_Scale*cosPhi0 * sinTheta;
            
            
            
            vPtr [3] = m_Scale*cosPhi1 * cosTheta;
            vPtr [4] = m_Scale*sinPhi1*m_Squash;
            vPtr [5] = m_Scale* cosPhi1 * sinTheta;
            
            cPtr [0] = red;
            cPtr [1] = green;
            cPtr [2] = blue;
            cPtr [4] = red;
            cPtr [5] = green;
            cPtr [6] = blue;
            cPtr [3] = cPtr[7] = 255;
            
            cPtr += 2*4;
            
            vPtr += 2*3;
        }
        
//        blue+=colorIncrment;
//        red-=colorIncrment;
//        green += colorIncrment;
    }
    
}

/**
 *  设置窗口及投影坐标的位置
 */
-(void)setClipping
{
    float aspectRatio;
    //指定了近裁面和远裁面的距离。这两个值的意思是，任何远于1000或近于0.1的对象都将被过滤掉
    const float zNear = 0.1;
    const float zFar = 1000;
    
    //设定视角为60度
    const float fieldOfView = 60.0;
    
    GLfloat    size;
    //获取屏幕的尺寸大小
    CGRect frame = [[UIScreen mainScreen] bounds];
    
    //根据屏幕的尺寸计算最终屏幕的纵横比例 (它的高度和宽度的值决定了相对高度的视域（FOV），如果将其翻转的话，将变成相对于宽度的视域。如果我们要设置一个60度视域，就像一个宽角度镜头，那么它将基于窗口的高度而非宽度。当渲染到一个非正方形的屏幕上时尤为重要。)
    aspectRatio=(float)frame.size.width/(float)frame.size.height;
    [self initProjectionMatrix];
    
    //计算锥形视角的左右上下的限制值 (你可以把它想象成3D空间中的虚拟窗口。原点在屏幕中央，所以x轴和y轴的值都是从-size到+size。这就是为什么会有GLKMathDegreesToRadians (fieldOfView) / 2.0将窗口分为两部分——视角的角度是从-30度到+30度的。乘以zNear就可以计算出近剪裁面在坐标轴各个方向上的大小。这就是正切函数的作用了，眼睛在z轴上，到原点的距离是zNear，视域被z轴分为上下两部分各为30度，所以就可以明白size就是近剪裁面在x和y轴上的长度)
    size = zNear * tanf(GLKMathDegreesToRadians (fieldOfView) / 2.0);
    
    // 设置视图窗口的大小 和 坐标系统
    glFrustumf(-size, size, -size /aspectRatio, size /aspectRatio, zNear, zFar);//这个函数非常Powerful。它实现了Surface和坐标系之间的映射关系。它是以透视投影的方式来进行映射的
    glViewport(0, 0, frame.size.width, frame.size.height); //设置视口，一般为屏幕的大小。不过你可以根据需要来设置坐标和宽度、高度
    
}@end
