program p
implicit none
character(1)::a(3)
a=char([65,100,101])
if(any(a/=["A","d","e"])) error stop 1
if(char(kind=1,i=65)/="A") error stop 2
if(achar(65)/="A") error stop 3
print *,a(1),a(2),a(3)
end program
