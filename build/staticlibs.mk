
PROJECT_OBJDIR=$(PROJECT_HOME)/build/.objects/
LIBS+=-lm
#include $(PROJECT_HOME)/web/http_pkt_sorter/staticlibs.mk
include $(SHOTODOL_NET_HOME)/linux/platform_net/staticlibs.mk
