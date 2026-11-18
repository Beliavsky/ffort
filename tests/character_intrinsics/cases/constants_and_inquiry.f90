program p
implicit none
integer,parameter::k=kind(index('ab','b',kind=8)),n=index('banana','ana',.true.),nt=len_trim('a ')+1
character(*),parameter::a=adjustl(' a  '),b=adjustr(' b  ')
character(len=5)::s
character(len=5)::t
print *, k,n,nt,kind(index(s,t)),kind(len_trim(s,8)),kind(adjustl(s))
print '(a)', '<'//a//'>','<'//b//'>'
print *, len(adjustl(s)),len(adjustr(s))
end program
