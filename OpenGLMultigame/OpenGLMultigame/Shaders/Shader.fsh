//
//  Shader.fsh
//  OpenGLMultigame
//
//  Created by Spencer Pollock on 2017-03-30.
//  Copyright © 2017 HankSpencer. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
