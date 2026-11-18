program main
implicit none
integer::a(4)
a=[1,2,3,4]
call work(a*3,a>2,['aa','bb','cc','dd'],2)
contains
subroutine work(x,tf,ch,n)
integer,intent(in)::n
integer,intent(in)::x(n)
logical,intent(in)::tf(n)
character(*),intent(in)::ch(n)
print *,sum(x),count(tf),len(ch),ch
end subroutine
end program
