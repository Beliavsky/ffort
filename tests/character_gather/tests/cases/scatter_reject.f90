implicit none
character(3)::x(-1:1)=[character(3)::'one','two','tri']
integer::idx(4)=[1,-1,1,0]
x([1,-1])='abc'
end
