program main
implicit none
integer(8),parameter::p=scan(set='a',kind=8,string='aba',back=.true.)
character(3)::undefined,empty(0)
logical::uninitialized
print *, p, kind(p), kind(scan(undefined,'a')), kind(scan('a','a',uninitialized,8))
print *, size(scan(empty,'a')), kind(scan(empty,'a',kind=8))
end program
