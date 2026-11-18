implicit none
character (len=*), parameter :: newl = achar(10), mod_str = "in util_mod::", &
                                lower_case = "abcdefghijklmnopqrstuvwxyz", &
                                upper_case = "ABCDEFGHIJKLMNOPQRSTUVWXYZ",mod_name="util_mod", &
                                newline = char(10),bad_char="???"
character (len=20), parameter :: str_ratio_diff="ratio_diff", str_none="none",str_simple="simple",str_log="log", &
                                 str_diff="diff",str_trans(3)=[str_ratio_diff,str_diff,str_none]
print *,newl==achar(10),newline==char(10)
print '(a)',mod_str//":",mod_name,bad_char
print '(a)',lower_case,upper_case
print *,str_trans==[str_ratio_diff,str_diff,str_none]
end
