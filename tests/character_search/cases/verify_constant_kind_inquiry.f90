program main
implicit none
integer(8),parameter::p=verify(set='a',kind=8,string='aba',back=.true.)
character(3)::undefined,empty(0)
logical::uninitialized
print *, p, kind(p), kind(verify(undefined,'a')), kind(verify('a','a',uninitialized,8))
print *, size(verify(empty,'a')), kind(verify(empty,'a',kind=8))
end program
