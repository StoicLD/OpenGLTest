// Include standard headers
#include <stdio.h>
#include <stdlib.h>

// Include GLEW
#include <GL/glew.h>

// Include GLFW
#include <GLFW/glfw3.h>

#include <SDL2/SDL_image.h>
#include <SDL2/SDL.h>

#include <shader.hpp>
#include <string>
#include <iostream>
GLFWwindow* window;

int cur_w;
int cur_h;
int scale_w;
int scale_h;
int resolution_w;
int resolution_h;
int crop_x;
int crop_y;
int crop_w;
int crop_h;
int overlay_x;
int overlay_y;

static const GLchar *k_default_vertex_shader_string =
        "attribute vec2 position;\n"
        "varying vec2 _uv;\n"
        "void main(void) {\n"
        "  gl_Position = vec4(position, 0, 1);\n"
        "  vec2 uv = position * 0.5 + 0.5;\n"
        "  _uv = uv;\n"
        "}\n";


std::string ConcatFragmentShader2(const char* glslStr, const char* defaultTransitionStr, const char *fragmentShaderTemplateStr) {
    if (strlen(glslStr) == 0) {
        std::cout << "error: empty glsl file" << std::endl;
    }

    const char *transitionString = strlen(glslStr) ? glslStr : defaultTransitionStr;
    if (strlen(transitionString) == 0) {
        std::cout << "error: transition function in glsl not found" << std::endl;
    }

    size_t len = strlen(fragmentShaderTemplateStr) + strlen(transitionString);

    // 拼接后的 fragment shader
    char *outputString = new char[len * sizeof(char) + 1];
    snprintf(outputString, len * sizeof(outputString), fragmentShaderTemplateStr, transitionString);
    std::string str(outputString);

    delete[] outputString;

    return str;
}

//计算并设置需要传入shader的参数
void Calculate(int m_nDstW, int m_nDstH, int m_cur_w, int m_cur_h)
{
    int w = m_cur_w * m_nDstH / m_cur_h;
    int h = m_cur_h * m_nDstW / m_cur_w;
    int iw = (w < m_nDstW ? w : m_nDstW) / 2 * 2;
    int ih = (h < m_nDstH ? h : m_nDstH) / 2 * 2;

    int tmp_w = iw;
    int tmp_h = m_nDstH * iw / m_nDstW;
    if (m_nDstW * ih < iw * m_nDstH) {
        tmp_w = m_nDstW * ih / m_nDstH;
        tmp_h = ih;
    }

    scale_w = iw;
    scale_h = ih;
    resolution_w = m_nDstW;
    resolution_h = m_nDstH;
    crop_x = (iw - tmp_w) / 2;
    crop_y = (ih - tmp_h) / 2;
    crop_w = tmp_w;
    crop_h = tmp_h;

    overlay_x = (m_nDstW - iw) / 2;
    overlay_y = (m_nDstH - ih) / 2;

    std::cout<< "cur_w: " << cur_w << ", cur_h: " << cur_h << std::endl;
    std::cout<< "w: " << w << ", h: " << h << std::endl;
    std::cout<< "iw: " << iw << ", ih: " << ih << std::endl;

    std::cout<<"scale: w = " << iw << ", h = " << ih << std::endl;
    std::cout<<"crop: x = " << (iw - tmp_w) / 2 << ", y = " << (ih - tmp_h) << ", w = " << tmp_w << ", h = " << tmp_h << std::endl;
    std::cout<<"overlay: " << (m_nDstW - iw) / 2 << " : " << (m_nDstH - ih) / 2 << std::endl;
}


SDL_Surface* load_image(const char *imgPath) {
    // 背景图（视频帧）
    SDL_Surface *background = IMG_Load(imgPath);
    SDL_Surface *image_sur = SDL_ConvertSurfaceFormat(background, SDL_PIXELFORMAT_RGBA32, 0);
    SDL_FreeSurface(background);
    return image_sur;
}

/*
 * 尝试加载一张大小和window不一致的纹理
 * 然后在顶点着色器里面修改纹理映射方式。
 */

void SetUniformf(GLint p_id, GLint &uniform_id, const char* name, int value)
{
    uniform_id = glGetUniformLocation(p_id, name);
    glUniform1f(uniform_id, (float)value);
}


int main()
{
    int window_width = 540;
    int window_height = 960;
    // Initialise GLFW
//region GLFW窗口初始化
    if( !glfwInit() )
    {
        fprintf( stderr, "Failed to initialize GLFW\n" );
        getchar();
        return -1;
    }

    glfwWindowHint(GLFW_SAMPLES, 4);
    //glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
    //glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
    glewExperimental = GL_TRUE;

    // Open a window and create its OpenGL context
    window = glfwCreateWindow( window_width, window_height, "Tutorial 02 - Red triangle", NULL, NULL);
    if( window == NULL ){
        fprintf( stderr, "Failed to open GLFW window. If you have an Intel GPU, they are not 3.3 compatible. Try the 2.1 version of the tutorials.\n" );
        getchar();
        glfwTerminate();
        return -1;
    }
    glfwMakeContextCurrent(window);

    // Initialize GLEW
    if (glewInit() != GLEW_OK) {
        fprintf(stderr, "Failed to initialize GLEW\n");
        getchar();
        glfwTerminate();
        return -1;
    }

    // Ensure we can capture the escape key being pressed below
    glfwSetInputMode(window, GLFW_STICKY_KEYS, GL_TRUE);

    // Dark blue background
    glClearColor(0.0f, 0.0f, 0.4f, 0.0f);

    //endregion
    
    // Create and compile our GLSL program from the shaders
    GLuint programID = LoadShaders( "../shader/SimpleVertexShader.glsl", "../shader/SimpleFragmentShader.glsl" );

    // Get a handle for our buffers
    GLuint position = glGetAttribLocation(programID, "position");

    //这里应该是对应window中的点
    static const GLfloat g_vertex_buffer_data[] = {
            -1.0f, -1.0f,
            1.0f, -1.0f,
            -1.0f, 1.0f,
            -1.0f, 1.0f,
            1.0f, -1.0f,
            1.0f, 1.0f
    };

    GLuint vertexbuffer;
    glGenBuffers(1, &vertexbuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(g_vertex_buffer_data), g_vertex_buffer_data, GL_STATIC_DRAW);

//region 读取设置texture
    //读取设置texture
    const char* imgPath = "/Users/lidong/Pictures/tree.jpg";
    SDL_Surface *image_sur1 = load_image(imgPath);
    if(image_sur1 == nullptr)
    {
        std::cout << "read image from disk error!" << std::endl;
        return -1;
    }

    GLuint m_first_texture;

    GLint textureID;
    glActiveTexture(GL_TEXTURE0);
    glGenTextures(1, &m_first_texture);
    glBindTexture(GL_TEXTURE_2D, m_first_texture);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, image_sur1->w, image_sur1->h, 0, GL_RGBA, GL_UNSIGNED_BYTE, image_sur1->pixels);

    textureID = glGetUniformLocation(programID ,"to");
    glUniform1i(textureID, 0);
    //endregion
// Use our shader
//一定要先use program！！！，才能设置uniform变量！！
    glUseProgram(programID);

//region 计算并且设置uniform变量
    cur_w = image_sur1->w;
    cur_h = image_sur1->h;
    Calculate(window_width, window_height, image_sur1->w, image_sur1->h);
    GLint uniform_scale_w_id;
    GLint uniform_scale_h_id;
    GLint uniform_resolution_w_id;
    GLint uniform_resolution_h_id;
    GLint uniform_crop_x_id;
    GLint uniform_crop_y_id;
    GLint uniform_crop_w_id;
    GLint uniform_crop_h_id;
    GLint uniform_cur_w_id;
    GLint uniform_cur_h_id;
    GLint uniform_overlay_x_id;
    GLint uniform_overlay_y_id;

    SetUniformf(programID, uniform_scale_w_id, "scale_w", scale_w);

    SetUniformf(programID, uniform_scale_h_id, "scale_h", scale_h);
    SetUniformf(programID, uniform_resolution_w_id, "resolution_w", resolution_w);
    SetUniformf(programID, uniform_resolution_h_id, "resolution_h", resolution_h);
    SetUniformf(programID, uniform_crop_x_id, "crop_x", crop_x);
    SetUniformf(programID, uniform_crop_y_id, "crop_y", crop_y);
    SetUniformf(programID, uniform_crop_w_id, "crop_w", crop_w);
    SetUniformf(programID, uniform_crop_h_id, "crop_h", crop_h);

    SetUniformf(programID, uniform_cur_w_id, "cur_w", cur_w);
    SetUniformf(programID, uniform_cur_h_id, "cur_h", cur_h);

    SetUniformf(programID, uniform_overlay_x_id, "overlay_x", overlay_x);
    SetUniformf(programID, uniform_overlay_y_id, "overlay_y", overlay_y);

//endregion

    // 1rst attribute buffer : vertices
    glEnableVertexAttribArray(position);
    glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
    glVertexAttribPointer(
            position, // The attribute we want to configure
            2,                  // size
            GL_FLOAT,           // type
            GL_FALSE,           // normalized?
            0,                  // stride
            (void*)0            // array buffer offset
    );
    glViewport(0, 0, window_width, window_height);
    //glDisableVertexAttribArray(position);
    do{

        // Clear the screen
        //glViewport(0, 0, window_width, window_height);
        glClear( GL_COLOR_BUFFER_BIT );

        // Use our shader
//        glUseProgram(programID);
//
//        // 1rst attribute buffer : vertices
//        glEnableVertexAttribArray(position);
//        glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
//        glVertexAttribPointer(
//                position, // The attribute we want to configure
//                2,                  // size
//                GL_FLOAT,           // type
//                GL_FALSE,           // normalized?
//                0,                  // stride
//                (void*)0            // array buffer offset
//        );

        // Draw the triangle !
        glDrawArrays(GL_TRIANGLES, 0, 6); // 3 indices starting at 0 -> 1 triangle

//        glDisableVertexAttribArray(position);

        // Swap buffers
        glfwSwapBuffers(window);
        glfwPollEvents();

    } // Check if the ESC key was pressed or the window was closed
    while( glfwGetKey(window, GLFW_KEY_ESCAPE ) != GLFW_PRESS &&
           glfwWindowShouldClose(window) == 0 );

    glDisableVertexAttribArray(position);
    // Cleanup VBO
    glDeleteBuffers(1, &vertexbuffer);
    glDeleteProgram(programID);

    // Close OpenGL window and terminate GLFW
    glfwTerminate();

    return 0;
}

