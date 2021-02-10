local reduce = function(itr, fnc)
    local s = "" for t in itr do s = s..fnc(t) end return s
end

local get_type = function(s)
    return s:match("^ ?(%??[^ ]+) %$[^ ]+$") or "mixed"
end

local del_type = function(s)
    return s:match("^ ?[^ ]+ ?(%$[^ %!]+)!$") or s
end

local set_null = function(s)
    return s:match("^%?") and s:sub(2).."|null" or s
end

local get_var = function(s)
    return s:match("^ ?[^ ]* ?(%$[^ !]+)!?$") or ""
end

local get_args = function(s)
    return s:gmatch(" ?[^,]* ?[^,]+")
end

local get_fnc = function(id, fnc)
    return function(c)return fnc(c[id]or"")end
end

local get_indent = function()
    return vim.api.nvim_get_current_line():match("^%s+") or ""
end

-- DOC BLOCK

local doc_get_var = function(s)
    return " * @var "..set_null(get_type(s)).."\n"
end

local doc_get_param = function(s)
    return " * @param "..set_null(get_type(s)).." "..get_var(s).."\n"
end

local doc_get_params = function(s)
    return reduce(get_args(s), doc_get_param)
end

local doc_get_return = function(s)
    return s:match("^:") and " * @return "..set_null(s:match("^: ?(%?? ?[^ ]+)$")or""):gsub("%s", "").."\n"
end

-- PHP CODE

local php_get_var = function(s)
    return del_type(s)
end

local php_get_args = function (s)
    return reduce(get_args(s), function(s)return del_type(s):match(" ?([^!]*)!? ?")..", "end):sub(1, -3)
end

-- SNIPPETS

local get_property = function (type)
    return {
        "/**\n",
        {order=1,id="prop",transform=get_fnc("prop",doc_get_var)},
        " */\n",
        type.." ",
        {order=1,id="prop",is_input=true,transform=get_fnc("prop",php_get_var)},
        ";"
    }
end

local get_function = function (type)
    return {
        "/**\n",
        {order=2,id="args",transform=get_fnc("args",doc_get_params)},
        {order=3,id="rttype",transform=get_fnc("rttype",doc_get_return)},
        " */\n",
        type.." function ",
        {order=1,id="name",is_input=true},
        "(",
        {order=2,id="args",is_input=true,transform=get_fnc("args",php_get_args)},
        ")",
        {order=3,id="rttype",is_input=true},
        "\n{\n",
        {order=4,default=get_indent},
        {order=0,id=0},
        "\n}"
    }
end

if not _MOCK then
    return {
        get_property = get_property,
        get_function = get_function
    }
else
    return {
        get_type = get_type,
        del_type = del_type,
        set_null = set_null,
        get_var = get_var,
        get_args = get_args,
        get_fnc = get_fnc,
        doc_get_var = doc_get_var,
        doc_get_param = doc_get_param,
        doc_get_params = doc_get_params,
        doc_get_return = doc_get_return,
        php_get_var = php_get_var,
        php_get_args = php_get_args
    }
end
