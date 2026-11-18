module m
contains
function combine(s) result(v)
character(*),intent(in)::s(:)
character(sum(len_trim(s)))::v
v='abxx'
end function
end module
program p
use m
character(3)::s(3)
s=['ab ','x  ','end']
print *,len(combine(s)),combine(s)
print *,len(combine(s(1:0)))
end program
