#include "AppDelegate.h"
#include "CCLuaEngine.h"
#include "AudioEngine.h"
#include "cocos2d.h"
#include "lua_module_register.h"

#if (CC_TARGET_PLATFORM != CC_PLATFORM_LINUX)
#include "ide-support/CodeIDESupport.h"
#endif

#if (COCOS2D_DEBUG > 0) && (CC_CODE_IDE_DEBUG_SUPPORT > 0)
#include "runtime/Runtime.h"
#include "ide-support/RuntimeLuaImpl.h"
#endif

USING_NS_CC;
using namespace std;

mt19937 rnd;

int random_seed_glue(lua_State* L)
{
    rnd = mt19937(lua_tonumber(L, 1));
    return 0;
}

int random_glue(lua_State* L)
{
    lua_pushnumber(L, rnd());
    return 1;
}

AppDelegate::AppDelegate()
{
}

AppDelegate::~AppDelegate()
{
    experimental::AudioEngine::end();

#if (COCOS2D_DEBUG > 0) && (CC_CODE_IDE_DEBUG_SUPPORT > 0)
    // NOTE:Please don't remove this call if you want to debug with Cocos Code IDE
    RuntimeEngine::getInstance()->end();
#endif

}

//if you want a different context,just modify the value of glContextAttrs
//it will takes effect on all platforms
void AppDelegate::initGLContextAttrs()
{
    //set OpenGL context attributions,now can only set six attributions:
    //red,green,blue,alpha,depth,stencil
    GLContextAttrs glContextAttrs = {8, 8, 8, 8, 24, 8};

    GLView::setGLContextAttrs(glContextAttrs);
}

// If you want to use packages manager to install more packages,
// don't modify or remove this function
static int register_all_packages()
{
    return 0; //flag for packages manager
}

bool AppDelegate::applicationDidFinishLaunching()
{
    // set default FPS
    Director::getInstance()->setAnimationInterval(1.0 / 60.0f);

    // register lua module
    auto engine = LuaEngine::getInstance();
    ScriptEngineManager::getInstance()->setScriptEngine(engine);
    lua_State* L = engine->getLuaStack()->getLuaState();
    lua_module_register(L);

    register_all_packages();

    LuaStack* stack = engine->getLuaStack();
    stack->setXXTEAKeyAndSign("pUxpJt6L4KFn", strlen("pUxpJt6L4KFn"), "4cbmXep6nmAf", strlen("4cbmXep6nmAf"));

    lua_getglobal(stack->getLuaState(), "_G");
    lua_register(stack->getLuaState(), "randomSeed", random_seed_glue);
    lua_register(stack->getLuaState(), "random", random_glue);

#if (COCOS2D_DEBUG > 0) && (CC_CODE_IDE_DEBUG_SUPPORT > 0)
    // NOTE:Please don't remove this call if you want to debug with Cocos Code IDE
    auto runtimeEngine = RuntimeEngine::getInstance();
    runtimeEngine->addRuntime(RuntimeLuaImpl::create(), kRuntimeEngineLua);
    runtimeEngine->start();
#else
    if (engine->executeScriptFile("src/main.lua"))
    {
        return false;
    }
#endif

    return true;
}

// This function will be called when the app is inactive. When comes a phone call,it's be invoked too
void AppDelegate::applicationDidEnterBackground()
{
    Director::getInstance()->stopAnimation();

    experimental::AudioEngine::pauseAll();
}

// this function will be called when the app is active again
void AppDelegate::applicationWillEnterForeground()
{
    Director::getInstance()->startAnimation();

    experimental::AudioEngine::resumeAll();
}
