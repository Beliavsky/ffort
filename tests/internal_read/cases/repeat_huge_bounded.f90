program p
implicit none
character(40)::text
integer::a(2)
text='9223372036854775807*6'
read(text,*) a
if(any(a/=6)) stop 1
print *,1
end program
