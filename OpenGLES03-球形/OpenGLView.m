//
//  OpenGLView.m
//  Tutorial01
//
//  Created by waqu on 2017/8/14.
//  Copyright © 2017年 com.waqu. All rights reserved.
//

#import "OpenGLView.h"
#import "GLUtils.h"

typedef struct {
    GLfloat x,y,z;
    GLfloat r,g,b;
} Vertex;

// 使用匿名 category 来声明私有成员
@interface OpenGLView()

- (void)setupLayer;
- (void)setupContext;
- (void)setupRenderBuffer;
- (void)destoryRenderAndFrameBuffer;
- (void)render;

@end

@implementation OpenGLView

+ (Class)layerClass {
    // 只有 [CAEAGLLayer class] 类型的 layer 才支持在其上描绘 OpenGL 内容。
    return [CAEAGLLayer class];
}

- (void)setupLayer
{
    _eaglLayer = (CAEAGLLayer*) self.layer;
    
    // CALayer 默认是透明的，必须将它设为不透明才能让其可见
    _eaglLayer.opaque = YES;
    
    // 设置描绘属性，在这里设置不维持渲染内容以及颜色格式为 RGBA8
    _eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}

- (void)setupContext {
    // 指定 OpenGL 渲染 API 的版本，在这里我们使用 OpenGL ES 2.0 
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    if (!_context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    // 设置为当前上下文
    if (![EAGLContext setCurrentContext:_context]) {
        _context = nil;

        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}

- (void)setupRenderBuffer {
    glGenRenderbuffers(1, &_colorRenderBuffer);
    // 设置为当前 renderbuffer
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    // 为 color renderbuffer 分配存储空间
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];    
}

- (void)setupFrameBuffer {    
    glGenFramebuffers(1, &_frameBuffer);
    // 设置为当前 framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, 
                              GL_RENDERBUFFER, _colorRenderBuffer);
}

- (void)destoryRenderAndFrameBuffer
{
    glDeleteFramebuffers(1, &_frameBuffer);
    _frameBuffer = 0;
    glDeleteRenderbuffers(1, &_colorRenderBuffer);
    _colorRenderBuffer = 0;
}

- (void)render {
    glClearColor(1.0, 1.0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glLineWidth(2.0);
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    _vertCount = 100; // 分割份数
    Vertex *vertext = (Vertex *)malloc(sizeof(Vertex) * _vertCount);
    memset(vertext, 0x00, sizeof(Vertex) * _vertCount);
    
    float a = 0.8; // 水平方向的半径
    float b = a * self.frame.size.width / self.frame.size.height;
    
    float delta = 2.0*M_PI/_vertCount;
    for (int i = 0; i < _vertCount; i++) {
        GLfloat x = a * cos(delta * i);
        GLfloat y = b * sin(delta * i);
        GLfloat z = 0.0;
        vertext[i] = (Vertex){x, y, z, x, y, x+y};
        
        printf("%f , %f\n", x, y);
    }
    
    glVertexAttribPointer(glGetAttribLocation(_program, "position"), 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), vertext);
    glEnableVertexAttribArray(glGetAttribLocation(_program, "position"));
    
    glVertexAttribPointer(glGetAttribLocation(_program, "color"), 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), vertext+sizeof(GLfloat)*3);
    glEnableVertexAttribArray(glGetAttribLocation(_program, "color"));
    
//    glDrawArrays(GL_LINES, 0, _vertCount);
    
    glDrawArrays(GL_LINE_LOOP, 0, _vertCount);
    
//    glDrawArrays(GL_TRIANGLE_FAN, 0, _vertCount);
    
//    glDrawArrays(GL_TRIANGLES, 0, _vertCount);

    [_context presentRenderbuffer:GL_RENDERBUFFER];
    
    free(vertext);
    vertext = NULL;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupLayer];        
        [self setupContext];
        [self setupGLProgram];
    }
    return self;
}

- (void)layoutSubviews {
    [EAGLContext setCurrentContext:_context];
    
    [self destoryRenderAndFrameBuffer];
    
    [self setupRenderBuffer];        
    [self setupFrameBuffer];    
    
    [self render];
}

- (void) setupGLProgram {
    NSString *vertFile = [[NSBundle mainBundle] pathForResource:@"Shader.vsh" ofType:nil];
    NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"Shader.fsh" ofType:nil];
    
    _program = createGLProgramFromFile(vertFile.UTF8String, fragFile.UTF8String);
    
    glUseProgram(_program);
}

- (void)setupVertexData {
    // 需要加static关键字，否则数据传输存在问题
    static GLfloat vertices[] = {
        0.0f,  0.5f, 0.0f,
        -0.5f, -0.5f, 0.0f,
        0.5f, -0.5f, 0.0f
    };
    GLint posSlot = glGetAttribLocation(_program, "position");
    glVertexAttribPointer(posSlot, 3, GL_FLOAT, GL_FALSE, 0, vertices);
    glEnableVertexAttribArray(posSlot);
    
//    static GLfloat colors[] = {
//        0.0f, 1.0f, 1.0f,
//        1.0f, 0.0f, 1.0f,
//        1.0f, 1.0f, 0.0f
//    };
    
    //纯蓝色
    static GLfloat colors[] = {
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f

    };
    GLint colorSlot = glGetAttribLocation(_program, "color");
    glVertexAttribPointer(colorSlot, 3, GL_FLOAT, GL_FALSE, 0, colors);
    glEnableVertexAttribArray(colorSlot);
}

@end
