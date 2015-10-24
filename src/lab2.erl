-module(lab2).
-behaviour(application).

-export([start/2, stop/1]).

start(_Type, _Args) ->
	application:start(crypto),
	application:start(inets),
	application:start(asn1),
	application:start(public_key),
	application:start(ssl),
	application:start(xmerl),
	application:start(compiler),
	application:start(syntax_tools),
	application:start(mochiweb),
	application:start(mochiweb_xpath),

    case httpc:request("https://en.wikipedia.org/wiki/List_of_programming_languages") of
        {ok,{_,_,Body}} ->
            Tree = mochiweb_html:parse(Body),
            Results = mochiweb_xpath:execute("//*[@id='mw-content-text']/*[@class='multicol']//li/a[position()<100]", Tree),
            lists:map(fun print_lang/1, lists:filter(fun check_link/1, Results)),
            {ok, 1};
        {error,Reason} -> 
            {error,Reason}
    end.

check_link(_A_tag) ->
	Href = "https://en.wikipedia.org" ++ unicode:characters_to_list(hd(mochiweb_xpath:execute("/a/@href", _A_tag))),
	%Text = hd(mochiweb_xpath:execute("/a/text()", _A_tag)),
	check_language(Href).

check_language(_Url) ->
	case httpc:request(_Url) of
        {ok,{_,_,Body}} ->
            Tree = mochiweb_html:parse(Body),
            LangInfo = mochiweb_xpath:execute("//table[@class='infobox vevent']//tr", Tree),
            case lists:filter(fun find_paradigm_in_row/1, LangInfo) of
            	[] -> false;
            	[Head|_] -> 
            		Paradigms = lists:map(fun(El) -> string:to_lower(unicode:characters_to_list(El)) end, mochiweb_xpath:execute("/tr//td//text()", Head)),
            		check_paradigms(Paradigms, {false, false})
            end;
        {error,Reason} -> 
            {error,Reason}
    end.

check_paradigms(_List, _Results) ->
	case _List of
		[Head|Tail] ->
			%{IsFunctional, IsImperative} = Head,
			case _Results of
				{_, true} ->
					false;
				{true, false} ->
					check_paradigms(Tail, {true, is_substring(Head, "imperative")});
				{false, false} ->
					check_paradigms(Tail, {is_substring(Head, "functional"), is_substring(Head, "imperative")})
			end;
		[] ->
			case _Results of
				{true, false} -> true;
				_ -> false
			end
	end.



find_paradigm_in_row(_Tr_tag) ->
	case mochiweb_xpath:execute("/tr//th//text()", _Tr_tag) of
		[] -> false;
		[Head|_] -> is_substring(string:to_lower(unicode:characters_to_list(Head)), "paradigm")			
	end.

is_substring(_String, _Substring) ->
	case string:str(_String, _Substring) of
		0 -> false;
		_ -> true
	end.

print_lang(_A_tag) ->
	Text = unicode:characters_to_list(hd(mochiweb_xpath:execute("/a/text()", _A_tag))),
	io:format("~s \n",[Text]).


stop(_State) ->
    ok.