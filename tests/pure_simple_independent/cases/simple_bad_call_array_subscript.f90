program purity_test
implicit none

print *,991
contains
simple integer function compute(xx) result(rr)
integer,intent(in)::xx
integer::aa(5)
aa=1
rr=aa(helper(xx))
end function compute
pure integer function helper(xx) result(rr)
integer, intent(in) :: xx
rr=xx
end function helper

end program
