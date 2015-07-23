/****************************************************************************
Copyright (c) 2010-2012 cocos2d-x.org
Copyright (c) 2013-2014 Chukong Technologies Inc.

http://www.cocos2d-x.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
****************************************************************************/

#include "platform/CCPlatformConfig.h"

#include <algorithm>

#include "platform/CCApplication.h"
#include "platform/CCFileUtils.h"
#include "math/CCGeometry.h"
#include "base/CCDirector.h"

NS_CC_BEGIN

Application* Application::sm_pSharedApplication = 0;

Application::Application()
{
    CCASSERT(! sm_pSharedApplication, "sm_pSharedApplication already exist");
    sm_pSharedApplication = this;
}

Application::~Application()
{
    CCASSERT(this == sm_pSharedApplication, "sm_pSharedApplication != this");
    sm_pSharedApplication = 0;
}

int Application::run()
{
    //initGLContextAttrs();
    if(!applicationDidFinishLaunching())
    {
        return 1;
    }

    /*
    long lastTime = 0L;
    long curTime = 0L;
    
    auto director = Director::getInstance();
    auto glview = director->getOpenGLView();
    
    // Retain glview to avoid glview being released in the while loop
    glview->retain();
    
    while (!glview->windowShouldClose())
    {
        lastTime = getCurrentMillSecond();
        
        director->mainLoop();
        glview->pollEvents();

        curTime = getCurrentMillSecond();
        if (curTime - lastTime < _animationInterval)
        {
            usleep(static_cast<useconds_t>((_animationInterval - curTime + lastTime)*1000));
        }
    }
    */

    /* Only work on Desktop
    *  Director::mainLoop is really one frame logic
    *  when we want to close the window, we should call Director::end();
    *  then call Director::mainLoop to do release of internal resources
    if (glview->isOpenGLReady())
    {
        director->end();
        director->mainLoop();
    }
    
    glview->release();
    */
    
    return 0;
}

void Application::setAnimationInterval(double interval)
{
}

Application::Platform Application::getTargetPlatform()
{
    return Platform::OS_MAC;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// static member function
//////////////////////////////////////////////////////////////////////////////////////////////////

Application* Application::getInstance()
{
    CCASSERT(sm_pSharedApplication, "sm_pSharedApplication not set");
    return sm_pSharedApplication;
}

// @deprecated Use getInstance() instead
Application* Application::sharedApplication()
{
    return Application::getInstance();
}

const char * Application::getCurrentLanguageCode()
{
    return "en";
}

LanguageType Application::getCurrentLanguage()
{
    return LanguageType::ENGLISH;

}

bool Application::openURL(const std::string &url)
{
    return false;
}

void Application::setResourceRootPath(const std::string& rootResDir)
{
    _resourceRootPath = rootResDir;
    if (_resourceRootPath[_resourceRootPath.length() - 1] != '/')
    {
        _resourceRootPath += '/';
    }
    FileUtils* pFileUtils = FileUtils::getInstance();
    std::vector<std::string> searchPaths = pFileUtils->getSearchPaths();
    searchPaths.insert(searchPaths.begin(), _resourceRootPath);
    pFileUtils->setSearchPaths(searchPaths);
}

const std::string& Application::getResourceRootPath(void)
{
    return _resourceRootPath;
}

NS_CC_END

