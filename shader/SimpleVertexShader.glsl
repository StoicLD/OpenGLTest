#version 120
// Input vertex data, different for all executions of this shader.
attribute vec2 position;

varying vec2 _uv;

//void main(void) {\n


void main(){
	//gl_Position = vec4(vertexPosition_modelspace, 1.0);
	//顶点着色器先做一个缩放处理，将纹理映射到清晰图像部分（如果不在0-1范围内，说明是模糊部分）

  	gl_Position = vec4(position, 0, 1);
  	vec2 uv = position * 0.5 + 0.5;
  	_uv = uv;
}

